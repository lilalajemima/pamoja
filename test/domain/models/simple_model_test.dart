import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/opportunity.dart';
import 'package:pamoja_app/domain/models/user_profile.dart';

void main() {
  group('Simple Model Tests', () {
    test('Opportunity has correct properties', () {
      const opportunity = Opportunity(
        id: '1',
        title: 'Test',
        description: 'Test',
        category: 'Test',
        location: 'Test',
        timeCommitment: 'Test',
        requirements: 'Test',
        imageUrl: 'test.jpg',
      );
      expect(opportunity.id, '1');
      expect(opportunity.title, 'Test');
    });

    test('UserProfile has default values', () {
      final profile = UserProfile(
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        avatarUrl: 'test.jpg',
        role: 'volunteer',
        skills: [],
        interests: [],
        volunteerHistory: [],
        certificates: [],
      );
      expect(profile.totalHours, 0);
      expect(profile.completedActivities, 0);
    });
  });
}