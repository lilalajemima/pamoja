import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String role;
  final List<String> skills;
  final List<String> interests;
  final List<Map<String, String>> volunteerHistory;
  final List<String> certificates;
  final int totalHours;
  final int completedActivities;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.skills,
    required this.interests,
    required this.volunteerHistory,
    required this.certificates,
    this.totalHours = 0,
    this.completedActivities = 0,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    avatarUrl,
    role,
    skills,
    interests,
    volunteerHistory,
    certificates,
    totalHours,
    completedActivities,
  ];

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
    List<String>? skills,
    List<String>? interests,
    List<Map<String, String>>? volunteerHistory,
    List<String>? certificates,
    int? totalHours,
    int? completedActivities,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      volunteerHistory: volunteerHistory ?? this.volunteerHistory,
      certificates: certificates ?? this.certificates,
      totalHours: totalHours ?? this.totalHours,
      completedActivities: completedActivities ?? this.completedActivities,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String,
      role: json['role'] as String,
      skills: List<String>.from(json['skills'] as List),
      interests: List<String>.from(json['interests'] as List),
      volunteerHistory: (json['volunteerHistory'] as List)
          .map((item) => Map<String, String>.from(item as Map))
          .toList(),
      certificates: List<String>.from(json['certificates'] as List),
      totalHours: json['totalHours'] as int? ?? 0,
      completedActivities: json['completedActivities'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'skills': skills,
      'interests': interests,
      'volunteerHistory': volunteerHistory,
      'certificates': certificates,
      'totalHours': totalHours,
      'completedActivities': completedActivities,
    };
  }
}