

class UserProfile {
  final String userId;
  final String name;
  final String phone;
  final String device;
  // List<Alert> alerts;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.device,
    // this.alerts = const [],
  });

  // From JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      device: json['device'] ?? '',
      // alerts:
      //     (json['alerts'] as List<dynamic>?)
      //         ?.map((a) => Alert.fromMap(a))
      //         .toList() ??
      //     [],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'device': device,
      // 'alerts': alerts.map((a) => a.toMap()).toList(),
    };
  }

  // From Firestore
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile(
      userId: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      device: data['device'] ?? '',
      // alerts:
      //     (data['alerts'] as List<dynamic>?)
      //         ?.map((a) => Alert.fromMap(a))
      //         .toList() ??
      //     [],
    );
  }

  // To Firestore
  static Map<String, dynamic> toFirestore(UserProfile profile) {
    return {
      'user_id': profile.userId,
      'name': profile.name,
      'phone': profile.phone,
      'device': profile.device,
      // 'alerts': profile.alerts.map((a) => a.toMap()).toList(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    String? phone,
    String? device,
    // List<Alert>? alerts,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      device: device ?? this.device,
      // alerts: alerts ?? this.alerts,
    );
  }
}
