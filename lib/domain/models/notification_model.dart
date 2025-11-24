// lib/domain/models/notification_model.dart
import 'package:equatable/equatable.dart';

enum NotificationType {
  opportunityPosted,
  applicationAccepted,
  applicationRejected,
  comment,
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool read;
  final DateTime timestamp;
  final String? relatedId; // opportunityId or postId
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.timestamp,
    this.relatedId,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        read,
        timestamp,
        relatedId,
        imageUrl,
      ];

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? read,
    DateTime? timestamp,
    String? relatedId,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
      relatedId: relatedId ?? this.relatedId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.opportunityPosted,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      relatedId: json['relatedId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'read': read,
      'timestamp': timestamp.toIso8601String(),
      'relatedId': relatedId,
      'imageUrl': imageUrl,
    };
  }
}