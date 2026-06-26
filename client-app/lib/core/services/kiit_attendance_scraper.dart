import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/features/attendance/model/scrape_exception.dart';

/// Scrapes the KIIT SAP portal invisibly using a [HeadlessInAppWebView].
///
/// This mirrors the implementation that is known to work end-to-end against the
/// live portal. Notes (learned from probing the live site):
///  * The portal is SAP NetWeaver Enterprise Portal; the attendance screen is a
///    WebDynpro ABAP iView served from a DIFFERENT origin
///    (https://wdprd.kiituniversity.net:8001). Main-page JS cannot read that
///    iframe (same-origin policy), so a UserScript is injected into ALL frames
///    (`forMainFrameOnly: false`) at `AT_DOCUMENT_START` (required to reach the
///    cross-origin iframe on Android). The copy that lands in the WebDynpro
///    iframe scrapes the table within its own origin and posts the result up to
///    the main frame via `window.top.postMessage`, which relays it to Dart.
///  * Year/Session are WebDynpro DropDownByKey listboxes, not native `select`s:
///    selecting means clicking the dropdown arrow (`#ID-btn`) then the option,
///    which triggers SAP's server round-trip. A plain `change` event does
///    nothing.
class KiitAttendanceScraper {
  static const String loginUrl =
      'https://kiitportal.kiituniversity.net/irj/portal/';

  // A desktop UA so the portal serves the full tree-navigation layout.
  static const String _desktopUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  // Generous safety net for a total network stall; normal failures are bounded
  // by the agent itself (login error, nav exhausted, no data, HTTP 500).
  static const Duration _safetyTimeout = Duration(minutes: 3);

  HeadlessInAppWebView? _headless;

  Future<AttendanceResult> scrape({
    required String username,
    required String password,
    required String academicYear,
    required String session,
    void Function(String message)? onLog,
  }) async {
    final completer = Completer<AttendanceResult>();
    var reloadCount = 0;
    var loginSubmitted = false;
    var navStarted = false;
    var done = false;

    void log(String m) {
      onLog?.call(m);
      if (kDebugMode) debugPrint('[scrape] $m');
    }

    log('Launching headless WebView and opening the portal '
        '($academicYear / $session)…');

    void finishOk(AttendanceResult r) {
      if (done) return;
      done = true;
      if (!completer.isCompleted) completer.complete(r);
    }

    void finishErr(ScrapeException e) {
      if (done) return;
      done = true;
      if (!completer.isCompleted) completer.completeError(e);
    }

    _headless = HeadlessInAppWebView(
      initialSize: const Size(1280, 900),
      initialUrlRequest: URLRequest(url: WebUri(loginUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        incognito: true,
        userAgent: _desktopUa,
        mediaPlaybackRequiresUserGesture: true,
        transparentBackground: true,
        // The attendance iView is on a different origin/port (wdprd:8001) and
        // the portal mixes resource origins — allow them so the iframe renders.
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      ),
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
          source: _agentJs(academicYear, session),
          // AT_DOCUMENT_START is required for the script to be injected into the
          // CROSS-ORIGIN WebDynpro iframe on Android (uses
          // addDocumentStartJavaScript, all-origins). END only reaches the
          // main/same-origin frames.
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: false,
        ),
      ]),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'kiitResult',
          callback: (args) {
            try {
              final result = _resultFromAgentJson(
                args.first as String,
                academicYear: academicYear,
                session: session,
              );
              log('Received attendance data: ${result.records.length} '
                  'subject(s)'
                  '${result.student?.name != null ? " for ${result.student!.name}" : ""}.');
              finishOk(result);
            } catch (e) {
              log('Failed to parse attendance JSON: $e');
              finishErr(
                ScrapeException(ScrapeErrorKind.unknown, 'Parse error: $e'),
              );
            }
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'kiitError',
          callback: (args) {
            try {
              final map =
                  jsonDecode(args.first as String) as Map<String, dynamic>;
              final code = (map['code'] ?? '').toString();
              final msg = (map['message'] ?? 'Scrape failed').toString();
              log('ERROR [$code]: $msg');
              finishErr(ScrapeException(_kindFromCode(code), msg));
            } catch (_) {
              log('ERROR: scrape failed (unparseable error payload)');
              finishErr(
                const ScrapeException(ScrapeErrorKind.unknown, 'Scrape failed'),
              );
            }
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'kiitLog',
          callback: (args) {
            if (args.isNotEmpty) log('• ${args.first}');
            return null;
          },
        );
      },
      onConsoleMessage: (controller, msg) {
        if (kDebugMode) debugPrint('[webview] ${msg.message}');
      },
      onReceivedError: (controller, request, error) {
        log('Network error loading ${request.url}: ${error.description}');
      },
      // wdprd:8001 requests a TLS client certificate; proceed without one
      // (same as a desktop browser) so the WebDynpro iframe still loads.
      onReceivedClientCertRequest: (controller, challenge) async {
        log('Client-certificate requested by ${challenge.protectionSpace.host}'
            ' — proceeding without a certificate.');
        return ClientCertResponse(
          certificatePath: '',
          action: ClientCertResponseAction.IGNORE,
        );
      },
      onLoadStop: (controller, url) async {
        if (done) return;
        log('Page loaded: $url');
        final raw = await controller.evaluateJavascript(
          source: 'window.__kiitLoginState ? window.__kiitLoginState() : null',
        );
        if (raw == null) {
          log('Agent not ready on this frame yet — waiting.');
          return;
        }
        Map<String, dynamic> st;
        try {
          st = jsonDecode(raw as String) as Map<String, dynamic>;
        } catch (_) {
          return;
        }
        final hasForm = st['hasForm'] == true;
        final loginErr = st['err'] == true;
        final is500 = st['is500'] == true;

        if (is500) {
          if (reloadCount++ < 6) {
            log('Portal returned an HTTP 500 page — reloading '
                '(attempt $reloadCount/6).');
            await controller.reload();
          } else {
            finishErr(
              const ScrapeException(
                ScrapeErrorKind.portalUnavailable,
                'The portal is returning errors (HTTP 500). Please try again.',
              ),
            );
          }
          return;
        }

        if (hasForm) {
          if (loginErr) {
            log('Login page shows an error message → invalid credentials.');
            finishErr(
              const ScrapeException(
                ScrapeErrorKind.invalidCredentials,
                'Your registration number or password is incorrect.',
              ),
            );
            return;
          }
          if (!loginSubmitted) {
            loginSubmitted = true;
            log('Login form detected — filling and submitting credentials.');
            await controller.evaluateJavascript(
              source: 'window.__kiitFillLogin('
                  '${jsonEncode(username)}, ${jsonEncode(password)})',
            );
          } else {
            // Login form re-rendered after submit with no progress => bad creds.
            log('Login form returned after submit with no error text → '
                'treating as invalid credentials.');
            finishErr(
              const ScrapeException(
                ScrapeErrorKind.invalidCredentials,
                'Your registration number or password is incorrect.',
              ),
            );
          }
          return;
        }

        // Logged in — kick off in-page navigation to the attendance iView.
        if (!navStarted) {
          navStarted = true;
          log('Logged in. Navigating: Student Self Service → '
              'Student Attendance Details…');
          await controller.evaluateJavascript(
            source: 'window.__kiitNavigate && window.__kiitNavigate()',
          );
        }
      },
    );

    log('Starting headless run.');
    await _headless!.run();
    try {
      return await completer.future.timeout(
        _safetyTimeout,
        onTimeout: () => throw const ScrapeException(
          ScrapeErrorKind.timeout,
          'Timed out while fetching your attendance. '
          'Check your internet connection and try again.',
        ),
      );
    } finally {
      log('Scrape finished — disposing WebView.');
      await dispose();
    }
  }

  Future<void> dispose() async {
    try {
      await _headless?.dispose();
    } catch (_) {}
    _headless = null;
  }

  /// Maps the agent's JSON (`{name, records:[{subject,attended,total,
  /// percentage}]}`) into this app's [AttendanceResult].
  static AttendanceResult _resultFromAgentJson(
    String json, {
    required String academicYear,
    required String session,
  }) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final name = (map['name'] ?? '').toString().trim();
    final rawRecords = (map['records'] as List?) ?? const [];

    int toInt(dynamic v) =>
        v is num ? v.round() : (double.tryParse('$v')?.round() ?? 0);
    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

    final records = rawRecords.whereType<Map>().map((e) {
      final m = e.cast<String, dynamic>();
      final attended = toInt(m['attended']);
      final total = toInt(m['total']);
      return AttendanceRecord(
        subject: (m['subject'] ?? '').toString(),
        present: attended,
        totalDays: total,
        absent: (total - attended) < 0 ? 0 : total - attended,
        percentage: toDouble(m['percentage']),
        facultyId: '',
        facultyName: '',
        excuses: 0,
      );
    }).where((r) => r.subject.trim().isNotEmpty).toList();

    return AttendanceResult(
      records: records,
      student: name.isEmpty ? null : StudentDetails(name: name),
      academicYear: academicYear,
      session: session,
      fetchedAt: DateTime.now(),
    );
  }

  static ScrapeErrorKind _kindFromCode(String code) {
    switch (code) {
      case 'no_data':
        return ScrapeErrorKind.noData;
      case 'invalid_credentials':
        return ScrapeErrorKind.invalidCredentials;
      case 'nav_failed':
        return ScrapeErrorKind.navigationFailed;
      default:
        return ScrapeErrorKind.unknown;
    }
  }

  // The injected agent. RAW string so JS regex backslashes survive; the two
  // config literals are substituted in (they are constants, not secrets —
  // credentials are passed separately via __kiitFillLogin at runtime).
  String _agentJs(String year, String session) => _agentTemplate
      .replaceAll('__YEAR__', year.replaceAll('"', r'\"'))
      .replaceAll('__SESSION__', session.replaceAll('"', r'\"'));
}

const String _agentTemplate = r'''
(function () {
  var IS_TOP = (window.top === window.self);
  var YEAR = "__YEAR__";
  var SESSION = "__SESSION__";
  function sleep(ms){ return new Promise(function (r) { setTimeout(r, ms); }); }

  // ===================== MAIN / TOP FRAME =====================
  if (IS_TOP) {
    if (window.__kiitTopInstalled) return;
    window.__kiitTopInstalled = true;

    function clog(m) {
      try { if (window.flutter_inappwebview) window.flutter_inappwebview.callHandler('kiitLog', m); } catch (e) {}
    }
    function cerr(code, message) {
      try { if (window.flutter_inappwebview) window.flutter_inappwebview.callHandler('kiitError', JSON.stringify({ code: code, message: message })); } catch (e) {}
    }

    // Relay messages posted up from the cross-origin WebDynpro iframe.
    window.addEventListener('message', function (ev) {
      var d = ev.data;
      if (typeof d === 'string' && d.indexOf('__KIIT__') === 0) {
        try {
          var msg = JSON.parse(d.substring(8));
          if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler(msg.handler, msg.payload);
          }
        } catch (e) {}
      }
    });

    // Fill + submit the SAP logon form (same origin as the main frame).
    window.__kiitFillLogin = function (u, p) {
      try {
        var uf = document.querySelector('#logonuidfield');
        var pf = document.querySelector('#logonpassfield');
        if (!uf || !pf) { clog('Login fields (#logonuidfield/#logonpassfield) not found.'); return 'no_form'; }
        uf.value = u; pf.value = p;
        clog('Filled username + password fields; submitting the logon form.');
        uf.dispatchEvent(new Event('input', { bubbles: true }));
        pf.dispatchEvent(new Event('input', { bubbles: true }));
        pf.dispatchEvent(new Event('change', { bubbles: true }));
        var btn = document.querySelector('input[type=submit]') ||
                  document.querySelector('#logonSubmit');
        var form = document.querySelector('#logonForm') ||
                   document.querySelector('#certLogonForm') ||
                   document.querySelector('form[name="certLogonForm"]') ||
                   document.querySelector('form');
        if (btn) { btn.click(); }
        else if (form && form.submit) { form.submit(); }
        else { pf.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, which: 13, bubbles: true })); }
        return 'submitted';
      } catch (e) { return 'err'; }
    };

    // Report the login page state back to Dart on every onLoadStop.
    window.__kiitLoginState = function () {
      var hasForm = !!document.querySelector('#logonpassfield');
      var body = document.body ? (document.body.innerText || '') : '';
      var err = hasForm && /logon failed|authentication failed|invalid|incorrect|not authorized|wrong user|user is locked|failed to/i.test(body);
      var is500 = !hasForm && /Internal Server Error|WebApplicationException|Application error occurred/i.test(body);
      return JSON.stringify({ hasForm: hasForm, err: err, is500: is500 });
    };

    // Collect every same-origin document (cross-origin frames throw -> skipped).
    function allDocs() {
      var docs = [document];
      (function rec(win) {
        try {
          for (var i = 0; i < win.frames.length; i++) {
            try {
              var d = win.frames[i].document;
              if (d) { docs.push(d); rec(win.frames[i]); }
            } catch (e) {}
          }
        } catch (e) {}
      })(window);
      return docs;
    }
    function clickByText(text, exact, skipTop) {
      var ds = allDocs();
      for (var k = skipTop ? 1 : 0; k < ds.length; k++) {
        var els = ds[k].querySelectorAll('a,span,td,div');
        for (var i = 0; i < els.length; i++) {
          var e = els[i];
          if (e.children.length === 0) {
            var t = (e.textContent || '').trim();
            if (exact ? (t === text) : (t.indexOf(text) >= 0)) {
              try { e.click(); } catch (_) {}
              return true;
            }
          }
        }
      }
      return false;
    }
    // Expand the left-nav "Student Self Service" folder (the tree node lives in
    // an inner content frame, so skipTop avoids hitting the top-level tab), then
    // poll for and click the "Student Attendance Details" service link.
    window.__kiitNavigate = async function () {
      if (window.__kiitNavStarted) return 'already';
      window.__kiitNavStarted = true;
      clog('Expanding the "Student Self Service" navigation folder.');
      clickByText('Student Self Service', true, true);
      for (var i = 0; i < 60; i++) {
        await sleep(1000);
        if (clickByText('Student Attendance Details', true, false)) {
          clog('Found and clicked "Student Attendance Details". Loading iView…');
          return 'clicked';
        }
        if (i % 5 === 4) {
          clog('Still waiting for the "Student Attendance Details" link (' + (i + 1) + 's)…');
          clickByText('Student Self Service', true, true);
        }
      }
      cerr('nav_failed', 'Could not reach Student Attendance Details (navigation links never appeared).');
      return 'not_found';
    };
    return;
  }

  // ===================== CHILD FRAME (WebDynpro iView) =====================
  function isAttendanceApp() {
    var ls = document.querySelectorAll('label');
    for (var i = 0; i < ls.length; i++) {
      if (ls[i].textContent.trim() === 'Year') return true;
    }
    return false;
  }
  function relay(handler, payload) {
    try {
      window.top.postMessage('__KIIT__' + JSON.stringify({ handler: handler, payload: payload }), '*');
    } catch (e) {}
  }
  // Open a WebDynpro DropDownByKey by its label and click the matching option.
  async function pick(labelText, optionText) {
    var ls = document.querySelectorAll('label'), label = null;
    for (var i = 0; i < ls.length; i++) {
      if (ls[i].textContent.trim() === labelText) { label = ls[i]; break; }
    }
    if (!label) return false;
    var inputId = label.getAttribute('for');
    var arrow = document.getElementById(inputId + '-btn') || document.getElementById(inputId);
    if (!arrow) return false;
    arrow.click();
    await sleep(900);
    var opts = document.querySelectorAll('[role=option]');
    var match = null, visMatch = null;
    for (var j = 0; j < opts.length; j++) {
      var o = opts[j];
      var v = (o.getAttribute('data-itemvalue1') || o.textContent || '').trim();
      if (v === optionText) {
        match = match || o;
        if (o.offsetParent !== null) { visMatch = o; break; }
      }
    }
    var target = visMatch || match;
    if (!target) { relay('kiitLog', 'Option "' + optionText + '" not found in the ' + labelText + ' dropdown.'); return false; }
    target.click();
    relay('kiitLog', 'Selected ' + labelText + ' = "' + optionText + '" (waiting for SAP round-trip).');
    await sleep(2600); // SAP server round-trip
    return true;
  }
  function scrape() {
    var name = '';
    var bt = document.body ? (document.body.innerText || '').replace(/\s+/g, ' ') : '';
    var m = bt.match(/Student Name\s*:\s*([A-Za-z .]+?)\s+Reg/i);
    if (m) name = m[1].trim();
    var records = [];
    var rows = document.querySelectorAll('[role=row]');
    for (var i = 0; i < rows.length; i++) {
      var gc = rows[i].querySelectorAll('[role=gridcell]');
      var cells = [];
      for (var j = 0; j < gc.length; j++) {
        var x = (gc[j].innerText || '').trim();
        if (x && !/select a row|spacebar/i.test(x)) cells.push(x);
      }
      // Columns: Subject, No.of Absent, No.of Present, Total No. of Days, Total %
      if (cells.length >= 5) {
        var subj = cells[0];
        var present = parseFloat(cells[2]);
        var total = parseFloat(cells[3]);
        var pct = parseFloat(cells[4]);
        if (subj && /[A-Za-z]/.test(subj) && !isNaN(present) && !isNaN(total) && !isNaN(pct)) {
          records.push({ subject: subj, attended: Math.round(present), total: Math.round(total), percentage: pct, facultyId: cells.length > 5 ? cells[5] : '' });
        }
      }
    }
    return { name: name, records: records };
  }
  function sendKey(el, k, code) {
    try { el.dispatchEvent(new KeyboardEvent('keydown', { key: k, code: k, keyCode: code, which: code, bubbles: true })); } catch (e) {}
    try { el.dispatchEvent(new KeyboardEvent('keyup', { key: k, code: k, keyCode: code, which: code, bubbles: true })); } catch (e) {}
  }
  function scrollEls() {
    var arr = [];
    var named = document.querySelectorAll('[role=scrollbar], [class*="scroll" i]');
    for (var i = 0; i < named.length; i++) arr.push(named[i]);
    var divs = document.querySelectorAll('div');
    for (var j = 0; j < divs.length; j++) {
      var e = divs[j];
      if (e.clientHeight > 0 && e.scrollHeight > e.clientHeight + 4) arr.push(e);
    }
    return arr;
  }
  // WebDynpro grids virtualize rows: only the visible window is in the DOM and
  // nodes recycle on scroll. Drive the table's own virtual scroll (keyboard nav
  // triggers a server round-trip; programmatic scrollTop alone does not),
  // accumulating UNIQUE rows until nothing new appears — so rows below the fold
  // are captured too.
  // Tunables. Worst case is roughly MAX_STEPS * SETTLE_MS of scrolling.
  // SETTLE_MS must be long enough to clear the SAP scroll round-trip (the table
  // re-renders rows from the server); the loop ends early once STABLE_LIMIT
  // consecutive steps add nothing, or aria-rowcount is reached. Fixed-delay
  // polling is used on purpose: the grid updates via cross-origin XHR deltas, so
  // a MutationObserver would fire mid-delta and settle before all rows arrive.
  var SCROLL_MAX_STEPS = 80;
  var SCROLL_SETTLE_MS = 900;
  var SCROLL_STABLE_LIMIT = 8;
  async function scrapeAll() {
    var seen = {}, out = [], name = '';
    function harvest() {
      var d = scrape();
      if (d.name) name = d.name;
      for (var i = 0; i < d.records.length; i++) {
        var r = d.records[i];
        // Dedupe on subject + facultyId: a subject split across faculty/sections
        // can legitimately appear as two rows, so subject alone would drop one.
        var key = ((r.subject || '') + '|' + (r.facultyId || '')).toLowerCase();
        if (key && !seen[key]) { seen[key] = 1; out.push(r); }
      }
    }
    var grid = document.querySelector('[role=grid],[role=treegrid]');
    var expected = grid ? (parseInt(grid.getAttribute('aria-rowcount'), 10) || 0) : 0;
    harvest();
    var last = -1, stable = 0;
    for (var step = 0; step < SCROLL_MAX_STEPS; step++) {
      var rows = document.querySelectorAll('[role=row]');
      var lastRow = rows.length ? rows[rows.length - 1] : null;
      if (lastRow) {
        var cell = lastRow.querySelector('[role=gridcell]') || lastRow;
        try { cell.focus(); } catch (e) {}
        try { cell.click(); } catch (e) {}
        sendKey(cell, 'End', 35);
        sendKey(cell, 'PageDown', 34);
        sendKey(cell, 'ArrowDown', 40);
        sendKey(cell, 'ArrowDown', 40);
        try { lastRow.scrollIntoView({ block: 'end' }); } catch (e) {}
        try { lastRow.dispatchEvent(new WheelEvent('wheel', { deltaY: 800, bubbles: true })); } catch (e) {}
      }
      var els = scrollEls();
      for (var s = 0; s < els.length; s++) {
        try {
          els[s].scrollTop = els[s].scrollHeight;
          els[s].dispatchEvent(new Event('scroll', { bubbles: true }));
        } catch (e) {}
      }
      await sleep(SCROLL_SETTLE_MS); // allow the scroll round-trip to re-render rows
      harvest();
      if (expected > 0 && out.length >= expected - 1) break; // -1: header counted
      if (out.length === last) { stable++; if (stable >= SCROLL_STABLE_LIMIT) break; } else { stable = 0; }
      last = out.length;
    }
    return { name: name, records: out };
  }
  async function run() {
    if (window.__kiitRan) return;
    window.__kiitRan = true;
    try {
      relay('kiitLog', 'Attendance iView loaded. Setting filters…');
      await pick('Year', YEAR);
      await pick('Session', SESSION);
      var bs = document.querySelectorAll('[role=button]'), btn = null;
      for (var i = 0; i < bs.length; i++) {
        if (/submit/i.test(bs[i].innerText || '')) { btn = bs[i]; break; }
      }
      if (btn) { relay('kiitLog', 'Clicking Submit to load the attendance table.'); btn.click(); await sleep(3000); }
      else { relay('kiitLog', 'Submit button not found; reading whatever is rendered.'); }
      relay('kiitLog', 'Reading the attendance table (scrolling for all rows)…');
      var data = await scrapeAll();
      if (!data || data.records.length === 0) {
        relay('kiitError', JSON.stringify({ code: 'no_data', message: 'The attendance table was empty for the selected year/session.' }));
        return;
      }
      relay('kiitLog', 'Scraped ' + data.records.length + ' subject row(s)' + (data.name ? ' for ' + data.name : '') + '.');
      relay('kiitResult', JSON.stringify(data));
    } catch (e) {
      relay('kiitError', JSON.stringify({ code: 'scrape_error', message: String(e) }));
    }
  }
  (async function () {
    if (window.__kiitChildRan) return;
    window.__kiitChildRan = true;
    var isWd = /wdprd|webdynpro|ZWDA/i.test(location.href);
    if (isWd) relay('kiitLog', 'Agent injected into WebDynpro frame: ' + location.host);
    for (var i = 0; i < 45; i++) {
      if (isAttendanceApp()) {
        relay('kiitLog', 'Attendance form ready in ' + location.host);
        await run();
        return;
      }
      await sleep(700);
    }
    if (isWd) relay('kiitLog', 'WebDynpro frame loaded but the Year/Session form never appeared (' + location.host + ').');
  })();
})();
''';
