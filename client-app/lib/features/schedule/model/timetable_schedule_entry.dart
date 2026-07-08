class ScheduleEntry {
  final String? subject;
  final String? room;
  final String? time;

  /// Faculty for the class. The timetable JSON carries this as `teacher` — a
  /// list of names (occasionally a single string, or absent on older data).
  final List<String>? teacher;

  ScheduleEntry({
    this.subject,
    this.room,
    this.time,
    this.teacher,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      subject: json['subject'],
      room: json['room'],
      time: json['time'],
      teacher: _parseTeacher(json['teacher']),
    );
  }

  static List<String>? _parseTeacher(dynamic raw) {
    if (raw is List) {
      final names = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return names.isEmpty ? null : names;
    }
    if (raw is String && raw.trim().isNotEmpty) return [raw.trim()];
    return null;
  }

  /// Faculty lines for display, one per row: up to two names, each on its own
  /// line, plus an "& others" line when there are more than two. Empty when no
  /// faculty is listed.
  List<String> get teacherLines {
    if (teacher == null || teacher!.isEmpty) return const [];
    final names = teacher!;
    if (names.length <= 2) return names;
    return [names[0], names[1], '& others'];
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'room': room,
      'time': time,
      'teacher': teacher,
    };
  }
}
