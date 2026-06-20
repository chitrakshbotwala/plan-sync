import 'package:plan_sync/core/models/hud_notices_action_model.dart';

class HudNoticeModel {
  final int id;
  final String title;
  final String description;
  final ActionModel? action;

  const HudNoticeModel({
    required this.id,
    required this.title,
    required this.description,
    this.action,
  });

  factory HudNoticeModel.fromMap(Map data) => HudNoticeModel(
        id: data['id'],
        title: data['title'],
        description: data['description'],
        action: data['action'] != null
            ? ActionModel.fromJson(data['action'])
            : null,
      );
}
