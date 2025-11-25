import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/opportunity.dart';

void main() {
  group('Opportunity Model', () {
    test('should create opportunity from json', () {
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
      expect(opportunity.category, 'Environment');
    });

    test('should convert opportunity to json', () {
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
    });
  });
}