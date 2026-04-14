class StudyMethod {
  final String title;
  final String description;
  final int focusMinutes;
  final int breakMinutes;
  final int revisionMinutes; // ✅ NEW
  final String videoUrl;

  const StudyMethod({
    required this.title,
    required this.description,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.revisionMinutes, // ✅ NEW
    required this.videoUrl,
  });

  /// Convert from JSON
  factory StudyMethod.fromJson(Map<String, dynamic> json) {
    return StudyMethod(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      focusMinutes: json['focusMinutes'] ?? 25,
      breakMinutes: json['breakMinutes'] ?? 5,
      revisionMinutes: json['revisionMinutes'] ?? 10, // ✅ default
      videoUrl: json['videoUrl'] ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'focusMinutes': focusMinutes,
      'breakMinutes': breakMinutes,
      'revisionMinutes': revisionMinutes, // ✅ NEW
      'videoUrl': videoUrl,
    };
  }

  /// Copy method (useful for updates)
  StudyMethod copyWith({
    String? title,
    String? description,
    int? focusMinutes,
    int? breakMinutes,
    int? revisionMinutes,
    String? videoUrl,
  }) {
    return StudyMethod(
      title: title ?? this.title,
      description: description ?? this.description,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      revisionMinutes: revisionMinutes ?? this.revisionMinutes,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}
