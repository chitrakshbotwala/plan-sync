import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/models/hud_notices_model.dart';

void main() {
  group('HudNoticeModel.fromMap', () {
    test('parses required fields', () {
      final notice = HudNoticeModel.fromMap({
        'id': 7,
        'title': 'Maintenance',
        'description': 'Service window 2-4am',
      });

      expect(notice.id, 7);
      expect(notice.title, 'Maintenance');
      expect(notice.description, 'Service window 2-4am');
      expect(notice.action, isNull);
    });

    test('parses optional action when present', () {
      final notice = HudNoticeModel.fromMap({
        'id': 8,
        'title': 'Update available',
        'description': 'Tap to update',
        'action': {
          'label': 'Open',
          'iosUrl': 'https://example.com/ios',
          'androidUrl': 'https://example.com/android',
        },
      });

      expect(notice.action, isNotNull);
      expect(notice.action!.label, 'Open');
      expect(notice.action!.iosUrl, 'https://example.com/ios');
      expect(notice.action!.androidUrl, 'https://example.com/android');
    });
  });
}
