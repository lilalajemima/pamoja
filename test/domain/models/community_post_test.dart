import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/community_post.dart';

void main() {
  group('CommunityPost', () {
    // Use final instead of const for DateTime
    final testPost = CommunityPost(
      id: '1',
      authorName: 'John Doe',
      authorAvatar: 'avatar.jpg',
      content: 'Test content',
      timestamp: DateTime(2024, 1, 1),
      likes: 10,
      comments: 5,
    );

    test('should create CommunityPost with correct properties', () {
      expect(testPost.id, '1');
      expect(testPost.authorName, 'John Doe');
      expect(testPost.content, 'Test content');
      expect(testPost.likes, 10);
      expect(testPost.comments, 5);
    });

    test('props should contain all properties', () {
      expect(testPost.props, [
        '1',
        'John Doe',
        'avatar.jpg',
        'Test content',
        DateTime(2024, 1, 1),
        10,
        5,
      ]);
    });

    test('should create CommunityPost from json', () {
      final json = {
        'id': '1',
        'authorName': 'John Doe',
        'authorAvatar': 'avatar.jpg',
        'content': 'Test content',
        'timestamp': '2024-01-01T00:00:00.000',
        'likes': 10,
        'comments': 5,
      };

      final post = CommunityPost.fromJson(json);

      expect(post.id, '1');
      expect(post.authorName, 'John Doe');
      expect(post.content, 'Test content');
      expect(post.likes, 10);
      expect(post.comments, 5);
      expect(post.timestamp, DateTime(2024, 1, 1));
    });

    test('should convert CommunityPost to json', () {
      final json = testPost.toJson();

      expect(json['id'], '1');
      expect(json['authorName'], 'John Doe');
      expect(json['content'], 'Test content');
      expect(json['likes'], 10);
      expect(json['comments'], 5);
      expect(json['timestamp'], '2024-01-01T00:00:00.000');
    });

    test('copyWith should update specified fields', () {
      final updated = testPost.copyWith(
        likes: 20,
        content: 'Updated content',
      );

      expect(updated.id, '1');
      expect(updated.likes, 20);
      expect(updated.content, 'Updated content');
      expect(updated.authorName, 'John Doe'); // unchanged
    });

    test('should be equal when properties are same', () {
      final post1 = CommunityPost(
        id: '1',
        authorName: 'John',
        authorAvatar: 'avatar.jpg',
        content: 'Content',
        timestamp: DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
      );

      final post2 = CommunityPost(
        id: '1',
        authorName: 'John',
        authorAvatar: 'avatar.jpg',
        content: 'Content',
        timestamp: DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
      );

      expect(post1, post2);
    });

    test('should not be equal when properties differ', () {
      final post1 = CommunityPost(
        id: '1',
        authorName: 'John',
        authorAvatar: 'avatar.jpg',
        content: 'Content',
        timestamp: DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
      );

      final post2 = CommunityPost(
        id: '2', // different id
        authorName: 'John',
        authorAvatar: 'avatar.jpg',
        content: 'Content',
        timestamp: DateTime(2024, 1, 1),
        likes: 10,
        comments: 5,
      );

      expect(post1, isNot(post2));
    });
  });
}