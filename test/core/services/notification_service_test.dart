// test/core/services/notification_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pamoja_app/core/services/notification_service.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockWriteBatch extends Mock implements WriteBatch {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

// Create fake classes for types that need fallback values
class DocumentReferenceFake extends Fake implements DocumentReference<Map<String, dynamic>> {}
class QuerySnapshotFake extends Fake implements QuerySnapshot<Map<String, dynamic>> {}
class QueryDocumentSnapshotFake extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class WriteBatchFake extends Fake implements WriteBatch {}
class DocumentSnapshotFake extends Fake implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late NotificationService notificationService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockNotificationsCollection;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockDocRef;
  late MockWriteBatch mockBatch;

  setUpAll(() {
    // Register fallback values for all Firestore types
    registerFallbackValue(DocumentReferenceFake());
    registerFallbackValue(QuerySnapshotFake());
    registerFallbackValue(QueryDocumentSnapshotFake());
    registerFallbackValue(WriteBatchFake());
    registerFallbackValue(DocumentSnapshotFake());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockNotificationsCollection = MockCollectionReference();
    mockUsersCollection = MockCollectionReference();
    mockDocRef = MockDocumentReference();
    mockBatch = MockWriteBatch();
    
    // Create NotificationService with our mock Firestore
    notificationService = NotificationService(firestore: mockFirestore);
  });

  group('NotificationService', () {
    group('createNotification', () {
      test('creates notification successfully', () async {
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockNotificationsCollection.add(any()))
            .thenAnswer((_) async => mockDocRef);

        await notificationService.createNotification(
          userId: 'user123',
          type: 'test',
          title: 'Test Title',
          message: 'Test Message',
          relatedId: 'rel123',
          imageUrl: 'https://example.com/image.jpg',
        );

        verify(() => mockNotificationsCollection.add(any())).called(1);
      });

      test('handles error when creating notification', () async {
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockNotificationsCollection.add(any()))
            .thenThrow(Exception('Failed to create'));

        // Should not throw, just print error
        await notificationService.createNotification(
          userId: 'user123',
          type: 'test',
          title: 'Test Title',
          message: 'Test Message',
        );

        verify(() => mockNotificationsCollection.add(any())).called(1);
      });
    });

    group('createNotificationForAllUsers', () {
      test('creates notifications for all users successfully', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockUser1 = MockQueryDocumentSnapshot();
        final mockUser2 = MockQueryDocumentSnapshot();
        
        when(() => mockUser1.id).thenReturn('user1');
        when(() => mockUser2.id).thenReturn('user2');
        
        when(() => mockFirestore.collection('users'))
            .thenReturn(mockUsersCollection);
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockUsersCollection.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs)
            .thenReturn([mockUser1, mockUser2]);
        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockNotificationsCollection.doc())
            .thenReturn(mockDocRef);
        when(() => mockBatch.set(any(), any()))
            .thenReturn(mockBatch);
        when(() => mockBatch.commit())
            .thenAnswer((_) async => []);

        await notificationService.createNotificationForAllUsers(
          type: 'announcement',
          title: 'New Announcement',
          message: 'Check this out!',
          relatedId: 'ann123',
          imageUrl: 'https://example.com/image.jpg',
        );

        verify(() => mockUsersCollection.get()).called(1);
        verify(() => mockBatch.commit()).called(1);
      });

      test('handles error when creating notifications for all users', () async {
        when(() => mockFirestore.collection('users'))
            .thenReturn(mockUsersCollection);
        when(() => mockUsersCollection.get())
            .thenThrow(Exception('Failed to get users'));

        // Should not throw, just print error
        await notificationService.createNotificationForAllUsers(
          type: 'announcement',
          title: 'New Announcement',
          message: 'Check this out!',
        );

        verify(() => mockUsersCollection.get()).called(1);
      });
    });

    group('notifyNewOpportunity', () {
      test('sends notification for new opportunity', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        
        when(() => mockFirestore.collection('users'))
            .thenReturn(mockUsersCollection);
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockUsersCollection.get())
            .thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);
        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockBatch.commit()).thenAnswer((_) async => []);

        await notificationService.notifyNewOpportunity(
          opportunityTitle: 'Beach Cleanup',
          opportunityId: 'opp123',
          imageUrl: 'https://example.com/image.jpg',
        );

        verify(() => mockUsersCollection.get()).called(1);
      });
    });

    group('notifyApplicationStatus', () {
      test('sends acceptance notification', () async {
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockNotificationsCollection.add(any()))
            .thenAnswer((_) async => mockDocRef);

        await notificationService.notifyApplicationStatus(
          userId: 'user123',
          opportunityTitle: 'Beach Cleanup',
          accepted: true,
          opportunityId: 'opp123',
        );

        verify(() => mockNotificationsCollection.add(any())).called(1);
      });

      test('sends rejection notification', () async {
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockNotificationsCollection.add(any()))
            .thenAnswer((_) async => mockDocRef);

        await notificationService.notifyApplicationStatus(
          userId: 'user123',
          opportunityTitle: 'Beach Cleanup',
          accepted: false,
          opportunityId: 'opp123',
        );

        verify(() => mockNotificationsCollection.add(any())).called(1);
      });
    });

    group('notifyNewComment', () {
      test('sends notification for new comment', () async {
        when(() => mockFirestore.collection('notifications'))
            .thenReturn(mockNotificationsCollection);
        when(() => mockNotificationsCollection.add(any()))
            .thenAnswer((_) async => mockDocRef);

        await notificationService.notifyNewComment(
          postAuthorId: 'author123',
          commenterName: 'John Doe',
          postId: 'post123',
        );

        verify(() => mockNotificationsCollection.add(any())).called(1);
      });
    });
  });
}