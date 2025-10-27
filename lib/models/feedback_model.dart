class FeedbackModel {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final String message;
  final double rating;
  final bool isRead;
  final DateTime? createdAt;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.message,
    required this.rating,
    this.isRead = false,
    this.createdAt,
  });

  // Convert a FeedbackModel into a Map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'message': message,
      'rating': rating,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Create a FeedbackModel from a Map
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      message: json['message'] as String,
      rating: (json['rating'] as num).toDouble(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}