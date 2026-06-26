import 'package:flutter/material.dart';

class AttendanceActivityLog extends StatefulWidget {
  const AttendanceActivityLog({super.key, required this.logs});
  final List<String> logs;

  @override
  State<AttendanceActivityLog> createState() => _AttendanceActivityLogState();
}

class _AttendanceActivityLogState extends State<AttendanceActivityLog> {
  final ScrollController _scrollController = ScrollController();
  int _lastLogCount = 0;

  @override
  void initState() {
    super.initState();
    _lastLogCount = widget.logs.length;
  }

  @override
  void didUpdateWidget(AttendanceActivityLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs.length != _lastLogCount) {
      _lastLogCount = widget.logs.length;
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    if (logs.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Activity log',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: logs
                    .map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $l',
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
