import 'package:equatable/equatable.dart';

enum ActivityStatus {
  applied,
  confirmed,
  completed,
  cancelled,
}

class VolunteerActivity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final ActivityStatus status;
  final DateTime? date;
  final double progress;

  const VolunteerActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.date,
    this.progress = 0.0,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    status,
    date,
    progress,
  ];

  VolunteerActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    ActivityStatus? status,
    DateTime? date,
    double? progress,
  }) {
    return VolunteerActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      date: date ?? this.date,
      progress: progress ?? this.progress,
    );
  }

  String get statusLabel {
    switch (status) {
      case ActivityStatus.applied:
        return 'Applied';
      case ActivityStatus.confirmed:
        return 'Confirmed';
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory VolunteerActivity.fromJson(Map<String, dynamic> json) {
    return VolunteerActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      status: ActivityStatus.values.firstWhere(
            (e) => e.toString() == 'ActivityStatus.${json['status']}',
        orElse: () => ActivityStatus.applied,
      ),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'date': date?.toIso8601String(),
      'progress': progress,
    };
  }
}