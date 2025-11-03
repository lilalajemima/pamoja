import 'package:equatable/equatable.dart';

class CommunityPost extends Equatable {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });

  @override
  List<Object?> get props => [
    id,
    authorName,
    authorAvatar,
    content,
    timestamp,
    likes,
    comments,
  ];

  CommunityPost copyWith({
    String? id,
    String? authorName,
    String? authorAvatar,
    String? content,
    DateTime? timestamp,
    int? likes,
    int? comments,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      likes: json['likes'] as int,
      comments: json['comments'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'comments': comments,
    };
  }
}