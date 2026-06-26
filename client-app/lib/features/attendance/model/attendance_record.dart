/// Attendance for a single subject, mirroring one row of the KIIT WebDynpro
/// "Student Attendance Details" table:
///   Subject | No.of Absent | No.of Present | Total No. of Days |
///   Total Percentage | Faculty ID | Faculty Name | No. of Excuses
class AttendanceRecord {
  final String subject;
  final int absent;
  final int present;
  final int totalDays;
  final double percentage;
  final String facultyId;
  final String facultyName;
  final int excuses;

  const AttendanceRecord({
    required this.subject,
    required this.absent,
    required this.present,
    required this.totalDays,
    required this.percentage,
    required this.facultyId,
    required this.facultyName,
    required this.excuses,
  });

  /// Values arrive from the injected JS agent as strings (the portal renders
  /// everything as text), so we coerce defensively.
  factory AttendanceRecord.fromScrape(Map<String, dynamic> json) {
    return AttendanceRecord(
      subject: _str(json['subject']),
      absent: _toInt(json['absent']),
      present: _toInt(json['present']),
      totalDays: _toInt(json['totalDays']),
      percentage: _toDouble(json['percentage']),
      facultyId: _str(json['facultyId']),
      facultyName: _str(json['facultyName']),
      excuses: _toInt(json['excuses']),
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      subject: _str(json['subject']),
      absent: _toInt(json['absent']),
      present: _toInt(json['present']),
      totalDays: _toInt(json['totalDays']),
      percentage: _toDouble(json['percentage']),
      facultyId: _str(json['facultyId']),
      facultyName: _str(json['facultyName']),
      excuses: _toInt(json['excuses']),
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'absent': absent,
        'present': present,
        'totalDays': totalDays,
        'percentage': percentage,
        'facultyId': facultyId,
        'facultyName': facultyName,
        'excuses': excuses,
      };

  /// Classes a student can still miss while staying at-or-above 75%, or 0
  /// when already below (use [classesToReach] for the recovery count instead).
  int get canSkip {
    if (percentage < 75) return 0;
    // floor(present/0.75) - totalDays
    final maxDays = (present / 0.75).floor();
    final skippable = maxDays - totalDays;
    return skippable < 0 ? 0 : skippable;
  }
}

/// Student header shown above the attendance table.
class StudentDetails {
  final String? school;
  final String? rollNo;
  final String? name;
  final String? regNo;
  final String? program;
  final String? semester;

  const StudentDetails({
    this.school,
    this.rollNo,
    this.name,
    this.regNo,
    this.program,
    this.semester,
  });

  factory StudentDetails.fromScrape(Map<String, dynamic> json) {
    String? clean(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return StudentDetails(
      school: clean(json['school']),
      rollNo: clean(json['rollNo']),
      name: clean(json['name']),
      regNo: clean(json['regNo']),
      program: clean(json['program']),
      semester: clean(json['semester']),
    );
  }

  factory StudentDetails.fromJson(Map<String, dynamic> json) =>
      StudentDetails.fromScrape(json);

  Map<String, dynamic> toJson() => {
        'school': school,
        'rollNo': rollNo,
        'name': name,
        'regNo': regNo,
        'program': program,
        'semester': semester,
      };
}

/// A complete attendance fetch: every subject plus the derived overall numbers.
class AttendanceResult {
  final List<AttendanceRecord> records;
  final StudentDetails? student;
  final String academicYear;
  final String session;
  final DateTime fetchedAt;

  const AttendanceResult({
    required this.records,
    required this.student,
    required this.academicYear,
    required this.session,
    required this.fetchedAt,
  });

  factory AttendanceResult.fromScrape(
    Map<String, dynamic> data, {
    required String academicYear,
    required String session,
  }) {
    final rawRecords = (data['records'] as List?) ?? const [];
    final records = rawRecords
        .whereType<Map>()
        .map((e) => AttendanceRecord.fromScrape(e.cast<String, dynamic>()))
        .where((r) => r.subject.trim().isNotEmpty)
        .toList();

    final rawStudent = data['student'];
    final student = rawStudent is Map
        ? StudentDetails.fromScrape(rawStudent.cast<String, dynamic>())
        : null;

    return AttendanceResult(
      records: records,
      student: student,
      academicYear: academicYear,
      session: session,
      fetchedAt: DateTime.now(),
    );
  }

  factory AttendanceResult.fromJson(Map<String, dynamic> json) {
    final rawRecords = (json['records'] as List?) ?? const [];
    return AttendanceResult(
      records: rawRecords
          .whereType<Map>()
          .map((e) => AttendanceRecord.fromJson(e.cast<String, dynamic>()))
          .toList(),
      student: json['student'] is Map
          ? StudentDetails.fromJson(
              (json['student'] as Map).cast<String, dynamic>())
          : null,
      academicYear: json['academicYear']?.toString() ?? '',
      session: json['session']?.toString() ?? '',
      fetchedAt: DateTime.tryParse(json['fetchedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'records': records.map((r) => r.toJson()).toList(),
        'student': student?.toJson(),
        'academicYear': academicYear,
        'session': session,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  int get totalPresent => records.fold(0, (sum, r) => sum + r.present);

  int get totalClasses => records.fold(0, (sum, r) => sum + r.totalDays);

  /// Overall attendance = mean of the per-subject percentages
  /// (Σ percentage / subject count).
  double get overallPercentage => records.isEmpty
      ? 0
      : records.fold<double>(0, (sum, r) => sum + r.percentage) /
          records.length;

  int get subjectsBelowThreshold =>
      records.where((r) => r.percentage < 75).length;

  bool get isEmpty => records.isEmpty;
}

// --- coercion helpers --------------------------------------------------------

String _str(dynamic v) => v?.toString().trim() ?? '';

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.round();
  return double.tryParse(v?.toString().trim() ?? '')?.round() ?? 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString().trim() ?? '') ?? 0;
}
