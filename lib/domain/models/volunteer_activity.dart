import 'package:equatable/equatable.dart';

enum ActivityStatus {
  applied,
  confirmed,
  rejected,
  completed,
}

class VolunteerActivity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final ActivityStatus status;
  final DateTime? appliedDate;
  final DateTime? confirmedDate;
  final DateTime? completedDate;
  final String? rejectionReason;

  const VolunteerActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.appliedDate,
    this.confirmedDate,
    this.completedDate,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    status,
    appliedDate,
    confirmedDate,
    completedDate,
    rejectionReason,
  ];

  VolunteerActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    ActivityStatus? status,
    DateTime? appliedDate,
    DateTime? confirmedDate,
    DateTime? completedDate,
    String? rejectionReason,
  }) {
    return VolunteerActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      confirmedDate: confirmedDate ?? this.confirmedDate,
      completedDate: completedDate ?? this.completedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
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
      case ActivityStatus.rejected:
        return 'Rejected';
    }
  }

  // Get progress value for the 3-step progress bar
  double get progressValue {
    switch (status) {
      case ActivityStatus.applied:
        return 0.33; // 1/3
      case ActivityStatus.confirmed:
        return 0.66; // 2/3
      case ActivityStatus.completed:
        return 1.0; // 3/3
      case ActivityStatus.rejected:
        return 0.0; // No progress for rejected
    }
  }

  // Get current step for display
  int get currentStep {
    switch (status) {
      case ActivityStatus.applied:
        return 1;
      case ActivityStatus.confirmed:
        return 2;
      case ActivityStatus.completed:
        return 3;
      case ActivityStatus.rejected:
        return 0;
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
      appliedDate: json['appliedDate'] != null ? DateTime.parse(json['appliedDate']) : null,
      confirmedDate: json['confirmedDate'] != null ? DateTime.parse(json['confirmedDate']) : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'appliedDate': appliedDate?.toIso8601String(),
      'confirmedDate': confirmedDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
}