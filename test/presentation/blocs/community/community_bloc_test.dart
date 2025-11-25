// test/presentation/blocs/community/community_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pamoja_app/presentation/blocs/community/community_bloc.dart';
import 'package:pamoja_app/domain/models/community_post.dart';

// Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
class MockQuery extends Mock implements Query {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late CommunityBloc communityBloc;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockCollectionReference mockPostsCollection;
  late MockDocumentReference mockPostDoc;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late MockQuery mockQuery;

  final testPosts = [
    CommunityPost(
      id: '1',
      authorName: 'John Doe',
      authorAvatar: 'avatar1.jpg',
      content: 'First post',
      timestamp: DateTime(2024, 1, 1),
      likes: 5,
      comments: 2,
    ),
    CommunityPost(
      id: '2',
      authorName: 'Jane Smith',
      authorAvatar: 'avatar2.jpg',
      content: 'Second post',
      timestamp: DateTime(2024, 1, 2),
      likes: 10,
      comments: 3,
    ),
  ];

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockPostsCollection = MockCollectionReference();
    mockPostDoc = MockDocumentReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockDocumentSnapshot = MockDocumentSnapshot();
    mockQuery = MockQuery();

    // Setup default mock behaviors
    when(() => mockFirestore.collection('posts')).thenReturn(mockPostsCollection);
    when(() => mockPostsCollection.doc(any())).thenReturn(mockPostDoc);
    when(() => mockPostsCollection.orderBy('timestamp', descending: true)).thenReturn(mockQuery);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user123');
    when(() => mockUser.displayName).thenReturn('Test User');

    communityBloc = CommunityBloc(
      firestore: mockFirestore,
      auth: mockAuth,
    );
  });

  tearDown(() {
    communityBloc.close();
  });

  group('CommunityBloc', () {
    group('LoadPosts', () {
      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityLoading, CommunityLoaded] when LoadPosts is successful',
        build: () {
          when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([
            _createMockDocumentSnapshot(testPosts[0]),
            _createMockDocumentSnapshot(testPosts[1]),
          ]);
          return communityBloc;
        },
        act: (bloc) => bloc.add(LoadPosts()),
        expect: () => [
          CommunityLoading(),
          CommunityLoaded(testPosts),
        ],
      );

      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityLoading, CommunityError] when LoadPosts fails',
        build: () {
          when(() => mockQuery.get()).thenThrow(Exception('Firestore error'));
          return communityBloc;
        },
        act: (bloc) => bloc.add(LoadPosts()),
        expect: () => [
          CommunityLoading(),
          CommunityError('Failed to load posts: Exception: Firestore error'),
        ],
      );
    });

    group('CreatePost', () {
      setUp(() {
        // Setup user data
        final mockUserDoc = MockDocumentSnapshot();
        final mockUsersCollection = MockCollectionReference();
        
        when(() => mockFirestore.collection('users')).thenReturn(mockUsersCollection);
        when(() => mockUsersCollection.doc('user123')).thenReturn(mockPostDoc);
        when(() => mockPostDoc.get()).thenAnswer((_) async => mockUserDoc);
        when(() => mockUserDoc.exists).thenReturn(true);
        when(() => mockUserDoc.data()).thenReturn({
          'name': 'Test User',
          'avatarUrl': 'test_avatar.jpg',
        });
      });

      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityLoading, CommunityOperationSuccess] when CreatePost is successful',
        build: () {
          when(() => mockPostsCollection.add(any())).thenAnswer((_) async => mockPostDoc);
          when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([
            _createMockDocumentSnapshot(testPosts[0]),
          ]);
          return communityBloc;
        },
        act: (bloc) => bloc.add(CreatePost('Test content')),
        expect: () => [
          CommunityLoading(),
          CommunityOperationSuccess('Post created successfully!', [testPosts[0]]),
        ],
        verify: (_) {
          verify(() => mockPostsCollection.add({
            'authorId': 'user123',
            'authorName': 'Test User',
            'authorAvatar': 'test_avatar.jpg',
            'content': 'Test content',
            'timestamp': any(named: 'timestamp'),
            'likes': 0,
            'comments': 0,
          })).called(1);
        },
      );

      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityError] when user is not logged in',
        build: () {
          when(() => mockAuth.currentUser).thenReturn(null);
          return communityBloc;
        },
        act: (bloc) => bloc.add(CreatePost('Test content')),
        expect: () => [
          CommunityError('You must be logged in to create a post'),
        ],
      );
    });

    group('EditPost', () {
      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityLoading, CommunityOperationSuccess] when EditPost is successful',
        build: () {
          // Mock post document check
          when(() => mockPostDoc.get()).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(() => mockDocumentSnapshot.data()).thenReturn({
            'authorId': 'user123', // Same user owns the post
          });
          
          when(() => mockPostDoc.update(any())).thenAnswer((_) async => null);
          when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([_createMockDocumentSnapshot(testPosts[0])]);
          
          return communityBloc;
        },
        act: (bloc) => bloc.add(EditPost('post1', 'Updated content')),
        expect: () => [
          CommunityLoading(),
          CommunityOperationSuccess('Post updated successfully!', [testPosts[0]]),
        ],
        verify: (_) {
          verify(() => mockPostDoc.update({
            'content': 'Updated content',
            'updatedAt': any(named: 'updatedAt'),
          })).called(1);
        },
      );

      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityError] when user does not own the post',
        build: () {
          when(() => mockPostDoc.get()).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(() => mockDocumentSnapshot.data()).thenReturn({
            'authorId': 'different-user', // Different user owns the post
          });
          
          return communityBloc;
        },
        act: (bloc) => bloc.add(EditPost('post1', 'Updated content')),
        expect: () => [
          CommunityError('You can only edit your own posts'),
        ],
      );
    });

    group('LikePost', () {
      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityLoading, CommunityLoaded] when LikePost is successful',
        build: () {
          when(() => mockPostDoc.update(any())).thenAnswer((_) async => null);
          when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([_createMockDocumentSnapshot(testPosts[0])]);
          
          return communityBloc;
        },
        act: (bloc) => bloc.add(LikePost('post1')),
        expect: () => [
          CommunityLoading(),
          CommunityLoaded([testPosts[0]]),
        ],
        verify: (_) {
          verify(() => mockPostDoc.update({
            'likes': any(named: 'likes'),
          })).called(1);
        },
      );
    });

    group('DeletePost', () {
      blocTest<CommunityBloc, CommunityState>(
        'emits [CommunityLoading, CommunityOperationSuccess] when DeletePost is successful',
        build: () {
          when(() => mockPostDoc.get()).thenAnswer((_) async => mockDocumentSnapshot);
          when(() => mockDocumentSnapshot.exists).thenReturn(true);
          when(() => mockDocumentSnapshot.data()).thenReturn({
            'authorId': 'user123', // User owns the post
          });
          
          when(() => mockPostDoc.delete()).thenAnswer((_) async => null);
          when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([_createMockDocumentSnapshot(testPosts[0])]);
          
          return communityBloc;
        },
        act: (bloc) => bloc.add(DeletePost('post1')),
        expect: () => [
          CommunityLoading(),
          CommunityOperationSuccess('Post deleted successfully!', [testPosts[0]]),
        ],
      );
    });
  });
}

// Helper function to create mock document snapshots
MockDocumentSnapshot _createMockDocumentSnapshot(CommunityPost post) {
  final mockSnapshot = MockDocumentSnapshot();
  when(() => mockSnapshot.id).thenReturn(post.id);
  when(() => mockSnapshot.data()).thenReturn({
    'authorName': post.authorName,
    'authorAvatar': post.authorAvatar,
    'content': post.content,
    'timestamp': Timestamp.fromDate(post.timestamp),
    'likes': post.likes,
    'comments': post.comments,
  });
  return mockSnapshot;
}