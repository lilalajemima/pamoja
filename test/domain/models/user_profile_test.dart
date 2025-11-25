import 'package:flutter_test/flutter_test.dart';
import 'package:pamoja_app/domain/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    // Use final instead of const
    final testProfile = UserProfile(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      avatarUrl: 'avatar.jpg',
      role: 'volunteer',
      skills: ['Flutter', 'Dart'],
      interests: ['Environment', 'Education'],
      volunteerHistory: [
        {'title': 'Beach Cleanup', 'hours': '5'},
      ],
      certificates: ['cert1', 'cert2'],
      totalHours: 50,
      completedActivities: 10,
    );

    test('should create UserProfile with correct properties', () {
      expect(testProfile.id, '1');
      expect(testProfile.name, 'John Doe');
      expect(testProfile.email, 'john@example.com');
      expect(testProfile.role, 'volunteer');
      expect(testProfile.skills, ['Flutter', 'Dart']);
      expect(testProfile.totalHours, 50);
      expect(testProfile.completedActivities, 10);
    });

    test('should have default values for totalHours and completedActivities', () {
      final profile = UserProfile(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        avatarUrl: 'avatar.jpg',
        role: 'volunteer',
        skills: [],
        interests: [],
        volunteerHistory: [],
        certificates: [],
      );

      expect(profile.totalHours, 0);
      expect(profile.completedActivities, 0);
    });

    test('props should contain all properties', () {
      expect(testProfile.props, [
        '1',
        'John Doe',
        'john@example.com',
        'avatar.jpg',
        'volunteer',
        ['Flutter', 'Dart'],
        ['Environment', 'Education'],
        [
          {'title': 'Beach Cleanup', 'hours': '5'},
        ],
        ['cert1', 'cert2'],
        50,
        10,
      ]);
    });

    test('should create UserProfile from json', () {
      final json = {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'avatarUrl': 'avatar.jpg',
        'role': 'volunteer',
        'skills': ['Flutter', 'Dart'],
        'interests': ['Environment', 'Education'],
        'volunteerHistory': [
          {'title': 'Beach Cleanup', 'hours': '5'},
        ],
        'certificates': ['cert1', 'cert2'],
        'totalHours': 50,
        'completedActivities': 10,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, '1');
      expect(profile.name, 'John Doe');
      expect(profile.skills, ['Flutter', 'Dart']);
      expect(profile.volunteerHistory, [
        {'title': 'Beach Cleanup', 'hours': '5'},
      ]);
      expect(profile.totalHours, 50);
    });

    test('should handle missing optional fields in fromJson', () {
      final json = {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'avatarUrl': 'avatar.jpg',
        'role': 'volunteer',
        'skills': [],
        'interests': [],
        'volunteerHistory': [],
        'certificates': [],
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.totalHours, 0);
      expect(profile.completedActivities, 0);
    });

    test('should convert UserProfile to json', () {
      final json = testProfile.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['skills'], ['Flutter', 'Dart']);
      expect(json['totalHours'], 50);
      expect(json['completedActivities'], 10);
    });

    test('copyWith should update specified fields', () {
      final updated = testProfile.copyWith(
        name: 'Jane Doe',
        totalHours: 100,
        skills: ['Flutter', 'Dart', 'Firebase'],
      );

      expect(updated.id, '1');
      expect(updated.name, 'Jane Doe');
      expect(updated.totalHours, 100);
      expect(updated.skills, ['Flutter', 'Dart', 'Firebase']);
      expect(updated.email, 'john@example.com'); // unchanged
    });

    test('should be equal when properties are same', () {
      final profile1 = UserProfile(
        id: '1',
        name: 'John',
        email: 'john@example.com',
        avatarUrl: 'avatar.jpg',
        role: 'volunteer',
        skills: ['Flutter'],
        interests: ['Tech'],
        volunteerHistory: [],
        certificates: [],
      );

      final profile2 = UserProfile(
        id: '1',
        name: 'John',
        email: 'john@example.com',
        avatarUrl: 'avatar.jpg',
        role: 'volunteer',
        skills: ['Flutter'],
        interests: ['Tech'],
        volunteerHistory: [],
        certificates: [],
      );

      expect(profile1, profile2);
    });

    test('should not be equal when properties differ', () {
      final profile1 = UserProfile(
        id: '1',
        name: 'John',
        email: 'john@example.com',
        avatarUrl: 'avatar.jpg',
        role: 'volunteer',
        skills: ['Flutter'],
        interests: ['Tech'],
        volunteerHistory: [],
        certificates: [],
      );

      final profile2 = UserProfile(
        id: '2', // different id
        name: 'John',
        email: 'john@example.com',
        avatarUrl: 'avatar.jpg',
        role: 'volunteer',
        skills: ['Flutter'],
        interests: ['Tech'],
        volunteerHistory: [],
        certificates: [],
      );

      expect(profile1, isNot(profile2));
    });
  });
}