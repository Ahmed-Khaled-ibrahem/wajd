import 'package:equatable/equatable.dart';

enum ReportStatus { open, inProgress, closed, cancelled }

class Report extends Equatable {
  final String id;
  final String reporterId;
  final String? childId;
  final String? assignedStaffId;
  final ReportStatus status;
  final String childName;
  final int childAge;
  final String childGender;
  final String childDescription;
  final String lastSeenLocation;
  final DateTime lastSeenTime;
  final String? childImageUrl;
  final List<String> additionalImages;
  final String reporterPhone;
  final String? reporterEmail;
  final String? additionalNotes;
  final bool isChildRegistered;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final String? closureNotes;
  final Map<String, dynamic>? metadata;

  const Report({
    required this.id,
    required this.reporterId,
    this.childId,
    this.assignedStaffId,
    required this.status,
    required this.childName,
    required this.childAge,
    required this.childGender,
    required this.childDescription,
    required this.lastSeenLocation,
    required this.lastSeenTime,
    this.childImageUrl,
    this.additionalImages = const [],
    required this.reporterPhone,
    this.reporterEmail,
    this.additionalNotes,
    required this.isChildRegistered,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.closureNotes,
    this.metadata,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      childId: json['child_id'] as String?,
      assignedStaffId: json['assigned_staff_id'] as String?,
      status: ReportStatus.values.firstWhere(
            (status) => status.toString().split('.').last == json['status'],
        orElse: () => ReportStatus.open,
      ),
      childName: json['child_name'] as String,
      childAge: json['child_age'] as int,
      childGender: json['child_gender'] as String,
      childDescription: json['child_description'] as String,
      lastSeenLocation: json['last_seen_location'] as String,
      lastSeenTime: DateTime.parse(json['last_seen_time'] as String),
      childImageUrl: json['child_image_url'] as String?,
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'] as List)
          : [],
      reporterPhone: json['reporter_phone'] as String,
      reporterEmail: json['reporter_email'] as String?,
      additionalNotes: json['additional_notes'] as String?,
      isChildRegistered: json['is_child_registered'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      closureNotes: json['closure_notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'child_id': childId,
      'assigned_staff_id': assignedStaffId,
      'status': status.toString().split('.').last,
      'child_name': childName,
      'child_age': childAge,
      'child_gender': childGender,
      'child_description': childDescription,
      'last_seen_location': lastSeenLocation,
      'last_seen_time': lastSeenTime.toIso8601String(),
      'child_image_url': childImageUrl,
      'additional_images': additionalImages,
      'reporter_phone': reporterPhone,
      'reporter_email': reporterEmail,
      'additional_notes': additionalNotes,
      'is_child_registered': isChildRegistered,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'closure_notes': closureNotes,
      'metadata': metadata,
    };
  }

  Report copyWith({
    String? id,
    String? reporterId,
    String? childId,
    String? assignedStaffId,
    ReportStatus? status,
    String? childName,
    int? childAge,
    String? childGender,
    String? childDescription,
    String? lastSeenLocation,
    DateTime? lastSeenTime,
    String? childImageUrl,
    List<String>? additionalImages,
    String? reporterPhone,
    String? reporterEmail,
    String? additionalNotes,
    bool? isChildRegistered,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    String? closureNotes,
    Map<String, dynamic>? metadata,
  }) {
    return Report(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      childId: childId ?? this.childId,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      status: status ?? this.status,
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      childGender: childGender ?? this.childGender,
      childDescription: childDescription ?? this.childDescription,
      lastSeenLocation: lastSeenLocation ?? this.lastSeenLocation,
      lastSeenTime: lastSeenTime ?? this.lastSeenTime,
      childImageUrl: childImageUrl ?? this.childImageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isChildRegistered: isChildRegistered ?? this.isChildRegistered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      closureNotes: closureNotes ?? this.closureNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    reporterId,
    childId,
    assignedStaffId,
    status,
    childName,
    childAge,
    childGender,
    childDescription,
    lastSeenLocation,
    lastSeenTime,
    childImageUrl,
    additionalImages,
    reporterPhone,
    reporterEmail,
    additionalNotes,
    isChildRegistered,
    createdAt,
    updatedAt,
    closedAt,
    closureNotes,
    metadata,
  ];
}