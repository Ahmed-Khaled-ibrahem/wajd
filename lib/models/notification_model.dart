import 'package:equatable/equatable.dart';

enum NotificationType {
  reportCreated,
  reportUpdated,
  reportClosed,
  reportAssigned,
  childFound,
  staffAssigned,
  generalInfo,
}

class AppNotification extends Equatable {
  final String? id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final String? reportId;
  final String? childId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.reportId,
    this.childId,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
        orElse: () => NotificationType.generalInfo,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      reportId: json['report_id'] as String?,
      childId: json['child_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'is_read': isRead,
      'report_id': reportId,
      'child_id': childId,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    String? reportId,
    String? childId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      reportId: reportId ?? this.reportId,
      childId: childId ?? this.childId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    message,
    isRead,
    reportId,
    childId,
    data,
    createdAt,
    readAt,
  ];
}
