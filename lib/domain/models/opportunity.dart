import 'package:equatable/equatable.dart';

class Opportunity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String timeCommitment;
  final String requirements;
  final String imageUrl;
  final DateTime? date;

  const Opportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.timeCommitment,
    required this.requirements,
    required this.imageUrl,
    this.date,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    location,
    timeCommitment,
    requirements,
    imageUrl,
    date,
  ];

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      location: json['location'] as String,
      timeCommitment: json['timeCommitment'] as String,
      requirements: json['requirements'] as String,
      imageUrl: json['imageUrl'] as String,
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'timeCommitment': timeCommitment,
      'requirements': requirements,
      'imageUrl': imageUrl,
      'date': date?.toIso8601String(),
    };
  }
}