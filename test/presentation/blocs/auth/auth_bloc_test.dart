// test/presentation/blocs/auth/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pamoja_app/presentation/blocs/auth/auth_bloc.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late AuthBloc authBloc;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockGoogleSignIn mockGoogleSignIn;

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

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    group('LoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, Authenticated] when login is successful',
        build: () {
          final mockUser = MockUser();
          final mockUserCredential = MockUserCredential();
          final mockDocSnapshot = MockDocumentSnapshot();
          final mockDocRef = MockDocumentReference();
          final mockCollection = MockCollectionReference();

          when(() => mockUser.uid).thenReturn('test-uid');
          when(() => mockUser.email).thenReturn('test@example.com');
          when(() => mockUserCredential.user).thenReturn(mockUser);
          
          when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockUserCredential);

          when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
          when(() => mockCollection.doc('test-uid')).thenReturn(mockDocRef);
          when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
          when(() => mockDocSnapshot.exists).thenReturn(true);
          when(() => mockDocSnapshot.data()).thenReturn({
            'name': 'Test User',
            'email': 'test@example.com',
          });

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
        'emits [AuthLoading, AuthError] when credentials are invalid',
        build: () {
          when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
            FirebaseAuthException(code: 'wrong-password'),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(LoginRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          AuthLoading(),
          AuthError('Incorrect password'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when user not found',
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
          email: 'nonexistent@example.com',
          password: 'password123',
        )),
        expect: () => [
          AuthLoading(),
          AuthError('No account found with this email'),
        ],
      );
    });

    group('SignupRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, EmailVerificationPending] when signup is successful',
        build: () {
          final mockUser = MockUser();
          final mockUserCredential = MockUserCredential();
          final mockDocRef = MockDocumentReference();
          final mockCollection = MockCollectionReference();

          when(() => mockUser.uid).thenReturn('new-uid');
          when(() => mockUser.email).thenReturn('newuser@example.com');
          when(() => mockUserCredential.user).thenReturn(mockUser);
          
          when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockUserCredential);

          when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
          when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});

          when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
          when(() => mockCollection.doc('new-uid')).thenReturn(mockDocRef);
          when(() => mockDocRef.set(any())).thenAnswer((_) async {});

          return authBloc;
        },
        act: (bloc) => bloc.add(SignupRequested(
          email: 'newuser@example.com',
          password: 'password123',
          name: 'New User',
        )),
        expect: () => [
          AuthLoading(),
          EmailVerificationPending(
            email: 'newuser@example.com',
            userId: 'new-uid',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when email already in use',
        build: () {
          when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
            FirebaseAuthException(code: 'email-already-in-use'),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(SignupRequested(
          email: 'existing@example.com',
          password: 'password123',
          name: 'Test User',
        )),
        expect: () => [
          AuthLoading(),
          AuthError('This email is already registered'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when password is weak',
        build: () {
          when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
            FirebaseAuthException(code: 'weak-password'),
          );

          return authBloc;
        },
        act: (bloc) => bloc.add(SignupRequested(
          email: 'newuser@example.com',
          password: '123',
          name: 'Test User',
        )),
        expect: () => [
          AuthLoading(),
          AuthError('Password is too weak. Use at least 6 characters'),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when logout is successful',
        build: () {
          when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
          when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

          return authBloc;
        },
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [Unauthenticated()],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthError] when logout fails',
        build: () {
          when(() => mockFirebaseAuth.signOut()).thenThrow(Exception('Logout failed'));

          return authBloc;
        },
        act: (bloc) => bloc.add(LogoutRequested()),
        expect: () => [
          isA<AuthError>().having(
            (state) => state.message,
            'message',
            contains('Logout failed'),
          ),
        ],
      );
    });

    group('CheckAuthStatus', () {
      blocTest<AuthBloc, AuthState>(
        'emits [Authenticated] when user is logged in',
        build: () {
          final mockUser = MockUser();
          final mockDocSnapshot = MockDocumentSnapshot();
          final mockDocRef = MockDocumentReference();
          final mockCollection = MockCollectionReference();

          when(() => mockUser.uid).thenReturn('test-uid');
          when(() => mockUser.email).thenReturn('test@example.com');
          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

          when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
          when(() => mockCollection.doc('test-uid')).thenReturn(mockDocRef);
          when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
          when(() => mockDocSnapshot.exists).thenReturn(true);
          when(() => mockDocSnapshot.data()).thenReturn({
            'name': 'Test User',
            'email': 'test@example.com',
          });

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

      blocTest<AuthBloc, AuthState>(
        'emits [Unauthenticated] when no user is logged in',
        build: () {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          return authBloc;
        },
        act: (bloc) => bloc.add(CheckAuthStatus()),
        expect: () => [Unauthenticated()],
      );
    });
  });
}