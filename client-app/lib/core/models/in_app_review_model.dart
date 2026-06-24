class InAppReviewCacheModel {
  int? lastRequested;
  int firstOpen;
  String? lastAppVersion;

  InAppReviewCacheModel({
    this.lastRequested,
    required this.firstOpen,
    this.lastAppVersion,
  });

  factory InAppReviewCacheModel.fromJson(Map<String, dynamic> json) {
    return InAppReviewCacheModel(
      lastRequested: json['lastRequested'] as int?,
      firstOpen: json['firstOpen'] as int,
      lastAppVersion: json['lastAppVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastRequested': lastRequested,
      'firstOpen': firstOpen,
      'lastAppVersion': lastAppVersion,
    };
  }
}
