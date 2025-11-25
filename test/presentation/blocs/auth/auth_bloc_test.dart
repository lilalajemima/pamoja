// test/presentation/blocs/auth/auth_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pamoja_app/presentation/blocs/auth/auth_bloc.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

void main() {
  group('AuthBloc', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthBloc authBloc;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockGoogleSignIn = MockGoogleSignIn();
      
      authBloc = AuthBloc(
        firebaseAuth: mockFirebaseAuth,
        firestore: mockFirestore,
        googleSignIn: mockGoogleSignIn,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('CheckAuthStatus', () {
      blocTest<AuthBloc, AuthState>(
        'emits Unauthenticated when no user is logged in',
        build: () {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [Unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits Authenticated when user is logged in',
        build: () {
          final mockUser = MockUser();
          final mockDocSnapshot = MockDocumentSnapshot();
          final mockDocRef = MockDocumentReference();
          final mockCollection = MockCollectionReference();
          
          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
          when(() => mockUser.uid).thenReturn('test-uid');
          when(() => mockUser.email).thenReturn('test@example.com');
          
          when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
          when(() => mockCollection.doc('test-uid')).thenReturn(mockDocRef);
          when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
          when(() => mockDocSnapshot.exists).thenReturn(true);
          when(() => mockDocSnapshot.data()).thenReturn({'name': 'Test User'});
          
          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [
          Authenticated(
            userId: 'test-uid',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ],
      );
    });

    group('LoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthLoading then Authenticated on successful login',
        build: () {
          final mockUser = MockUser();
          final mockUserCredential = MockUserCredential();
          final mockDocSnapshot = MockDocumentSnapshot();
          final mockDocRef = MockDocumentReference();
          final mockCollection = MockCollectionReference();
          
          when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockUserCredential);
          
          when(() => mockUserCredential.user).thenReturn(mockUser);
          when(() => mockUser.uid).thenReturn('test-uid');
          when(() => mockUser.email).thenReturn('test@example.com');
          
          when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
          when(() => mockCollection.doc('test-uid')).thenReturn(mockDocRef);
          when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
          when(() => mockDocSnapshot.exists).thenReturn(true);
          when(() => mockDocSnapshot.data()).thenReturn({'name': 'Test User'});
          
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginRequested(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          AuthLoading(),
          Authenticated(
            userId: 'test-uid',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthLoading then AuthError on failed login',
        build: () {
          when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
            FirebaseAuthException(code: 'user-not-found'),
          );
          
          return authBloc;
        },
        act: (bloc) => bloc.add(LoginRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          AuthLoading(),
          isA<AuthError>().having(
            (state) => state.message,
            'message',
            contains('No account found'),
          ),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits Unauthenticated on successful logout',
        build: () {
          when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
          when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
          
          return authBloc;
        },
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [Unauthenticated()],
      );
    });
  });
}