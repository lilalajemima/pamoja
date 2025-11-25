// test/presentation/blocs/tracker/tracker_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pamoja_app/core/services/notification_service.dart';
import 'package:pamoja_app/domain/models/volunteer_activity.dart';
import 'package:pamoja_app/presentation/blocs/tracker/tracker_bloc.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late TrackerBloc bloc;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockNotificationService = MockNotificationService();

    // Setup default mocks
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-user-id');
    
    // Mock notification service
    when(() => mockNotificationService.notifyApplicationStatus(
      userId: any(named: 'userId'),
      opportunityTitle: any(named: 'opportunityTitle'),
      accepted: any(named: 'accepted'),
      opportunityId: any(named: 'opportunityId'),
    )).thenAnswer((_) async => {});

    bloc = TrackerBloc(
      auth: mockAuth,
      firestore: mockFirestore,
      notificationService: mockNotificationService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('TrackerBloc', () {
    test('initial state is TrackerInitial', () {
      expect(bloc.state, isA<TrackerInitial>());
    });

    group('LoadActivities', () {
      blocTest<TrackerBloc, TrackerState>(
        'emits [TrackerLoading, TrackerLoaded] when successful',
        build: () {
          final mockApplicationsCollection = MockCollectionReference();
          final mockQuery1 = MockQuery();
          final mockQuery2 = MockQuery();
          final mockQuerySnapshot = MockQuerySnapshot();

          when(() => mockFirestore.collection('applications')).thenReturn(mockApplicationsCollection);
          when(() => mockApplicationsCollection.where('userId', isEqualTo: 'test-user-id'))
              .thenReturn(mockQuery1);
          when(() => mockQuery1.orderBy('appliedAt', descending: true))
              .thenReturn(mockQuery2);
          when(() => mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([]);

          return TrackerBloc(
            auth: mockAuth,
            firestore: mockFirestore,
            notificationService: mockNotificationService,
          );
        },
        act: (bloc) => bloc.add(LoadActivities()),
        expect: () => [
          isA<TrackerLoading>(),
          isA<TrackerLoaded>()
              .having((s) => s.upcomingActivities, 'upcoming', isEmpty)
              .having((s) => s.pastActivities, 'past', isEmpty),
        ],
      );

      blocTest<TrackerBloc, TrackerState>(
        'emits TrackerError when user is not logged in',
        build: () {
          when(() => mockAuth.currentUser).thenReturn(null);
          return TrackerBloc(
            auth: mockAuth,
            firestore: mockFirestore,
            notificationService: mockNotificationService,
          );
        },
        act: (bloc) => bloc.add(LoadActivities()),
        expect: () => [
          isA<TrackerLoading>(),
          isA<TrackerError>().having(
            (s) => s.message,
            'error message',
            'No user logged in',
          ),
        ],
      );
    });

    group('ApplyToOpportunity', () {
      blocTest<TrackerBloc, TrackerState>(
        'applies to opportunity successfully',
        build: () {
          final mockUsersCollection = MockCollectionReference();
          final mockApplicationsCollection = MockCollectionReference();
          final mockUserDocRef = MockDocumentReference();
          final mockUserDoc = MockDocumentSnapshot();
          final mockApplicationsRef = MockDocumentReference();
          
          // Create separate mock instances for different query chains
          final mockExistingQuery1 = MockQuery();
          final mockExistingQuery2 = MockQuery();
          final mockExistingSnapshot = MockQuerySnapshot();
          
          final mockReloadQuery1 = MockQuery();
          final mockReloadQuery2 = MockQuery();
          final mockReloadSnapshot = MockQuerySnapshot();

          // Mock users collection
          when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
          when(() => mockUsersCollection.doc('test-user-id')).thenReturn(mockUserDocRef);
          when(() => mockUserDocRef.get()).thenAnswer((_) async => mockUserDoc);
          when(() => mockUserDoc.data()).thenReturn({
            'name': 'Test User',
            'email': 'test@example.com',
            'avatarUrl': 'https://example.com/avatar.jpg',
          });

          // Mock applications collection - use multiple when clauses for different calls
          when(() => mockFirestore.collection('applications')).thenReturn(mockApplicationsCollection);
          
          // First call: check existing application
          when(() => mockApplicationsCollection.where('userId', isEqualTo: 'test-user-id'))
              .thenReturn(mockExistingQuery1);
          when(() => mockExistingQuery1.where('opportunityId', isEqualTo: 'opp-1'))
              .thenReturn(mockExistingQuery2);
          when(() => mockExistingQuery2.get()).thenAnswer((_) async => mockExistingSnapshot);
          when(() => mockExistingSnapshot.docs).thenReturn([]);

          // Mock adding application
          when(() => mockApplicationsCollection.add(any())).thenAnswer((_) async => mockApplicationsRef);
          
          // Second call: reload activities after applying
          // Use a counter to return different queries for different calls
          var callCount = 0;
          when(() => mockApplicationsCollection.where('userId', isEqualTo: 'test-user-id'))
              .thenAnswer((invocation) {
            callCount++;
            if (callCount == 1) {
              return mockExistingQuery1; // First call for existing check
            } else {
              return mockReloadQuery1; // Second call for reload
            }
          });
          
          when(() => mockReloadQuery1.orderBy('appliedAt', descending: true))
              .thenReturn(mockReloadQuery2);
          when(() => mockReloadQuery2.get()).thenAnswer((_) async => mockReloadSnapshot);
          when(() => mockReloadSnapshot.docs).thenReturn([]);

          return TrackerBloc(
            auth: mockAuth,
            firestore: mockFirestore,
            notificationService: mockNotificationService,
          );
        },
        act: (bloc) => bloc.add(
          ApplyToOpportunity(
            opportunityId: 'opp-1',
            opportunityTitle: 'Beach Cleanup',
            description: 'Clean the beach',
            imageUrl: 'https://example.com/beach.jpg',
          ),
        ),
        expect: () => [
          isA<TrackerOperationSuccess>()
              .having((s) => s.message, 'success message', 'Application submitted successfully!'),
        ],
      );
    });

    group('UpdateActivityStatus', () {
      blocTest<TrackerBloc, TrackerState>(
        'updates activity status to confirmed',
        build: () {
          final mockApplicationsCollection = MockCollectionReference();
          final mockUsersCollection = MockCollectionReference();
          final mockAppDoc = MockDocumentReference();
          final mockUserDoc = MockDocumentReference();
          
          // Query chains for reloading
          final mockReloadQuery1 = MockQuery();
          final mockReloadQuery2 = MockQuery();
          final mockReloadSnapshot = MockQuerySnapshot();
          
          // Mock applications collection update
          when(() => mockFirestore.collection('applications')).thenReturn(mockApplicationsCollection);
          when(() => mockApplicationsCollection.doc(any())).thenReturn(mockAppDoc);
          when(() => mockAppDoc.update(any())).thenAnswer((_) async => {});
          
          // Mock users collection update
          when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
          when(() => mockUsersCollection.doc('test-user-id')).thenReturn(mockUserDoc);
          when(() => mockUserDoc.update(any())).thenAnswer((_) async => {});

          // Mock reloading activities
          when(() => mockApplicationsCollection.where('userId', isEqualTo: 'test-user-id'))
              .thenReturn(mockReloadQuery1);
          when(() => mockReloadQuery1.orderBy('appliedAt', descending: true))
              .thenReturn(mockReloadQuery2);
          when(() => mockReloadQuery2.get()).thenAnswer((_) async => mockReloadSnapshot);
          when(() => mockReloadSnapshot.docs).thenReturn([]);

          return TrackerBloc(
            auth: mockAuth,
            firestore: mockFirestore,
            notificationService: mockNotificationService,
          );
        },
        act: (bloc) => bloc.add(
          UpdateActivityStatus(
            'activity-1',
            ActivityStatus.confirmed,
            opportunityTitle: 'Beach Cleanup',
            opportunityId: 'opp-1',
          ),
        ),
        expect: () => [
          isA<TrackerOperationSuccess>()
              .having((s) => s.message, 'success message', 'Status updated successfully!'),
        ],
        verify: (_) {
          verify(() => mockNotificationService.notifyApplicationStatus(
            userId: 'test-user-id',
            opportunityTitle: 'Beach Cleanup',
            accepted: true,
            opportunityId: 'opp-1',
          )).called(1);
        },
      );

      blocTest<TrackerBloc, TrackerState>(
        'updates activity status to completed',
        build: () {
          final mockApplicationsCollection = MockCollectionReference();
          final mockUsersCollection = MockCollectionReference();
          final mockAppDoc = MockDocumentReference();
          final mockUserDoc = MockDocumentReference();
          
          // Query chains for reloading
          final mockReloadQuery1 = MockQuery();
          final mockReloadQuery2 = MockQuery();
          final mockReloadSnapshot = MockQuerySnapshot();
          
          // Mock applications collection update
          when(() => mockFirestore.collection('applications')).thenReturn(mockApplicationsCollection);
          when(() => mockApplicationsCollection.doc(any())).thenReturn(mockAppDoc);
          when(() => mockAppDoc.update(any())).thenAnswer((_) async => {});
          
          // Mock users collection update
          when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
          when(() => mockUsersCollection.doc('test-user-id')).thenReturn(mockUserDoc);
          when(() => mockUserDoc.update(any())).thenAnswer((_) async => {});

          // Mock reloading activities
          when(() => mockApplicationsCollection.where('userId', isEqualTo: 'test-user-id'))
              .thenReturn(mockReloadQuery1);
          when(() => mockReloadQuery1.orderBy('appliedAt', descending: true))
              .thenReturn(mockReloadQuery2);
          when(() => mockReloadQuery2.get()).thenAnswer((_) async => mockReloadSnapshot);
          when(() => mockReloadSnapshot.docs).thenReturn([]);

          return TrackerBloc(
            auth: mockAuth,
            firestore: mockFirestore,
            notificationService: mockNotificationService,
          );
        },
        act: (bloc) => bloc.add(
          UpdateActivityStatus(
            'activity-1',
            ActivityStatus.completed,
            opportunityTitle: 'Beach Cleanup',
            opportunityId: 'opp-1',
          ),
        ),
        expect: () => [
          isA<TrackerOperationSuccess>(),
        ],
      );
    });
  });
}