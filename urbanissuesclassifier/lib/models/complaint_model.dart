import 'package:meta/meta.dart';

enum ComplaintType {
  pothole,
  garbage,
  paintedHump,
  unpaintedHump,
  other;

  String get dbValue {
    switch (this) {
      case ComplaintType.pothole:
        return 'pothole';
      case ComplaintType.garbage:
        return 'garbage';
      case ComplaintType.paintedHump:
        return 'painted_hump';
      case ComplaintType.unpaintedHump:
        return 'unpainted_hump';
      case ComplaintType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ComplaintType.pothole:
        return 'Pothole';
      case ComplaintType.garbage:
        return 'Garbage';
      case ComplaintType.paintedHump:
        return 'Painted Hump';
      case ComplaintType.unpaintedHump:
        return 'Unpainted Hump';
      case ComplaintType.other:
        return 'Other';
    }
  }

  static ComplaintType fromString(String value) {
    final v = value.toString().toLowerCase().trim();
    if (v.contains('pothole')) return ComplaintType.pothole;
    if (v.contains('garbage')) return ComplaintType.garbage;
    if (v.contains('painted_hump') || v.contains('painted hump')) {
      return ComplaintType.paintedHump;
    }
    if (v.contains('unpainted_hump') || v.contains('unpainted hump')) {
      return ComplaintType.unpaintedHump;
    }
    return ComplaintType.other;
  }
}

enum ComplaintStatus {
  pending,
  resolved;

  String get dbValue {
    switch (this) {
      case ComplaintStatus.pending:
        return 'pending';
      case ComplaintStatus.resolved:
        return 'resolved';
    }
  }

  String get displayName {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.resolved:
        return 'Resolved';
    }
  }

  static ComplaintStatus fromString(String value) {
    final v = value.toString().toLowerCase().trim();
    // Only 'resolved' stays resolved. Everything else (progress, reject, etc.) becomes 'pending'
    if (v.contains('resolved')) return ComplaintStatus.resolved;
    return ComplaintStatus.pending;
  }
}

@immutable
class ComplaintModel {
  final String id;
  final String userId;
  final ComplaintType type;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final ComplaintStatus status;
  final double confidenceScore;
  final String? imageUrl;
  final String phone;
  final DateTime reportedDate;

  const ComplaintModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.confidenceScore,
    this.imageUrl,
    required this.phone,
    required this.reportedDate,
  });

  ComplaintModel copyWith({
    String? id,
    String? userId,
    ComplaintType? type,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    ComplaintStatus? status,
    double? confidenceScore,
    String? imageUrl,
    String? phone,
    DateTime? reportedDate,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      reportedDate: reportedDate ?? this.reportedDate,
    );
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      type: ComplaintType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: ComplaintStatus.fromString(json['status'] as String),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      phone: json['phone'] as String? ?? '',
      reportedDate: DateTime.parse(json['reported_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.dbValue,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.dbValue,
      'confidence_score': confidenceScore,
      'image_url': imageUrl,
      'phone': phone,
      'reported_date': reportedDate.toIso8601String(),
    };
  }
}
