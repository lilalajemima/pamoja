// test/domain/models/simple_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/opportunity.dart';

void main() {
  group('Simple Model Tests', () {
    test('Opportunity should have correct string representation', () {
      const opportunity = Opportunity(
        id: '1',
        title: 'Test Opportunity',
        description: 'Test Description',
        category: 'Environment',
        location: 'Test Location',
        timeCommitment: '2 hours',
        requirements: 'None',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(opportunity.toString(), contains('Opportunity'));
      expect(opportunity.toString(), contains('Test Opportunity'));
    });

    test('Opportunity should be equal when properties match', () {
      const opportunity1 = Opportunity(
        id: '1',
        title: 'Test',
        description: 'Test',
        category: 'Test',
        location: 'Test',
        timeCommitment: 'Test',
        requirements: 'Test',
        imageUrl: 'https://example.com/image.jpg',
      );

      const opportunity2 = Opportunity(
        id: '1',
        title: 'Test',
        description: 'Test',
        category: 'Test',
        location: 'Test',
        timeCommitment: 'Test',
        requirements: 'Test',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(opportunity1, opportunity2);
    });

    test('Opportunity should not be equal when properties differ', () {
      const opportunity1 = Opportunity(
        id: '1',
        title: 'Test',
        description: 'Test',
        category: 'Test',
        location: 'Test',
        timeCommitment: 'Test',
        requirements: 'Test',
        imageUrl: 'https://example.com/image.jpg',
      );

      const opportunity2 = Opportunity(
        id: '2', // Different ID
        title: 'Test',
        description: 'Test',
        category: 'Test',
        location: 'Test',
        timeCommitment: 'Test',
        requirements: 'Test',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(opportunity1, isNot(opportunity2));
    });

    test('Opportunity fromJson should handle all fields', () {
      final json = {
        'id': '1',
        'title': 'Test Opportunity',
        'description': 'Test Description',
        'category': 'Environment',
        'location': 'Test Location',
        'timeCommitment': '2 hours',
        'requirements': 'None',
        'imageUrl': 'https://example.com/image.jpg',
      };

      final opportunity = Opportunity.fromJson(json);

      expect(opportunity.id, '1');
      expect(opportunity.title, 'Test Opportunity');
      expect(opportunity.description, 'Test Description');
      expect(opportunity.category, 'Environment');
    });

    test('Opportunity toJson should include all fields', () {
      const opportunity = Opportunity(
        id: '1',
        title: 'Test Opportunity',
        description: 'Test Description',
        category: 'Environment',
        location: 'Test Location',
        timeCommitment: '2 hours',
        requirements: 'None',
        imageUrl: 'https://example.com/image.jpg',
      );

      final json = opportunity.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'Test Opportunity');
      expect(json['description'], 'Test Description');
      expect(json['category'], 'Environment');
    });
  });
}