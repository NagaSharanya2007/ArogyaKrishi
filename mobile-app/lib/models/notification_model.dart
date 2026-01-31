/// Notification model for storing notification data
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'detection', 'reminder', 'alert'
  final DateTime createdAt;
  final bool isRead;
  final String? cropName;
  final String? diseaseName;
  final String language;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.cropName,
    this.diseaseName,
    required this.language,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      cropName: json['cropName'] as String?,
      diseaseName: json['diseaseName'] as String?,
      language: json['language'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'cropName': cropName,
      'diseaseName': diseaseName,
      'language': language,
      'metadata': metadata,
    };
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      cropName: cropName,
      diseaseName: diseaseName,
      language: language,
      metadata: metadata,
    );
  }
}
