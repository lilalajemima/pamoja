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
  late MockCollectionReference mockCollection;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    mockNotificationService = MockNotificationService();

    // Setup default mocks
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test-user-id');
    when(() => mockFirestore.collection('applications')).thenReturn(mockCollection);
    when(() => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo')))
        .thenReturn(mockQuery);
    when(() => mockQuery.orderBy(any(), descending: any(named: 'descending')))
        .thenReturn(mockQuery);
    when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
    when(() => mockQuerySnapshot.docs).thenReturn([]);

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
        build: () => bloc,
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
      setUp(() {
        final mockUserDoc = MockDocumentSnapshot();
        final mockUserDocRef = MockDocumentReference();
        final mockApplicationsRef = MockDocumentReference();
        final mockExistingQuery = MockQuery();
        final mockExistingSnapshot = MockQuerySnapshot();

        when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockUserDocRef);
        when(() => mockUserDocRef.get()).thenAnswer((_) async => mockUserDoc);
        when(() => mockUserDoc.data()).thenReturn({
          'name': 'Test User',
          'email': 'test@example.com',
          'avatarUrl': 'https://example.com/avatar.jpg',
        });

        when(() => mockFirestore.collection('applications')).thenReturn(mockCollection);
        when(() => mockCollection.where('userId', isEqualTo: 'test-user-id'))
            .thenReturn(mockExistingQuery);
        when(() => mockExistingQuery.where('opportunityId', isEqualTo: any(named: 'isEqualTo')))
            .thenReturn(mockExistingQuery);
        when(() => mockExistingQuery.get()).thenAnswer((_) async => mockExistingSnapshot);
        when(() => mockExistingSnapshot.docs).thenReturn([]);

        when(() => mockCollection.add(any())).thenAnswer((_) async => mockApplicationsRef);
      });

      blocTest<TrackerBloc, TrackerState>(
        'applies to opportunity successfully',
        build: () => bloc,
        act: (bloc) => bloc.add(
          ApplyToOpportunity(
            opportunityId: 'opp-1',
            opportunityTitle: 'Beach Cleanup',
            description: 'Clean the beach',
            imageUrl: 'https://example.com/beach.jpg',
          ),
        ),
        expect: () => [
          isA<TrackerLoading>(),
          isA<TrackerOperationSuccess>()
              .having((s) => s.message, 'success message', 'Application submitted successfully!'),
        ],
      );
    });

    group('UpdateActivityStatus', () {
      setUp(() {
        final mockAppDoc = MockDocumentReference();
        
        when(() => mockFirestore.collection('applications')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockAppDoc);
        when(() => mockAppDoc.update(any())).thenAnswer((_) async => {});
        
        // Mock user document update for completion
        final mockUserDoc = MockDocumentReference();
        when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockUserDoc);
        when(() => mockUserDoc.update(any())).thenAnswer((_) async => {});
      });

      blocTest<TrackerBloc, TrackerState>(
        'updates activity status to confirmed',
        build: () => bloc,
        act: (bloc) => bloc.add(
          UpdateActivityStatus(
            'activity-1',
            ActivityStatus.confirmed,
            opportunityTitle: 'Beach Cleanup',
            opportunityId: 'opp-1',
          ),
        ),
        expect: () => [
          isA<TrackerLoading>(),
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
        build: () => bloc,
        act: (bloc) => bloc.add(
          UpdateActivityStatus(
            'activity-1',
            ActivityStatus.completed,
            opportunityTitle: 'Beach Cleanup',
            opportunityId: 'opp-1',
          ),
        ),
        expect: () => [
          isA<TrackerLoading>(),
          isA<TrackerOperationSuccess>(),
        ],
      );
    });
  });
}