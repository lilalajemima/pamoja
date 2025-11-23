import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignupRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  SignupRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class GoogleSignInRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class ResendVerificationEmail extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String userId;
  final String email;
  final String name;

  Authenticated({
    required this.userId,
    required this.email,
    required this.name,
  });

  @override
  List<Object?> get props => [userId, email, name];
}

class Unauthenticated extends AuthState {}

class EmailVerificationPending extends AuthState {
  final String email;
  final String userId;

  EmailVerificationPending({
    required this.email,
    required this.userId,
  });

  @override
  List<Object?> get props => [email, userId];
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthBloc({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<ResendVerificationEmail>(_onResendVerificationEmail);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      final user = userCredential.user;
      if (user == null) {
        emit(AuthError('Authentication failed'));
        return;
      }

      // For login, we DON'T check email verification
      // Only check if user profile exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        emit(AuthError('User profile not found. Please sign up.'));
        await _firebaseAuth.signOut();
        return;
      }

      final userData = userDoc.data()!;

      emit(Authenticated(
        userId: user.uid,
        email: user.email!,
        name: userData['name'] ?? 'User',
      ));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }

      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );

      final user = userCredential.user;
      if (user == null) {
        emit(AuthError('Signup failed'));
        return;
      }

      // Update display name
      await user.updateDisplayName(event.name);

      // Send email verification
      await user.sendEmailVerification();

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': event.name.trim(),
        'email': event.email.trim(),
        'role': 'volunteer',
        'avatarUrl': 'https://i.pravatar.cc/300?u=${user.uid}',
        'skills': [],
        'interests': [],
        'volunteerHistory': [],
        'certificates': [],
        'totalHours': 0,
        'completedActivities': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      // Emit verification pending state ONLY for signup
      emit(EmailVerificationPending(
        email: user.email!,
        userId: user.uid,
      ));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        default:
          errorMessage = 'Signup failed: ${e.message}';
      }

      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onResendVerificationEmail(
    ResendVerificationEmail event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        // Don't emit error state here, just a success message
        // The UI will handle showing the snackbar
      }
    } catch (e) {
      emit(AuthError('Failed to send verification email: ${e.toString()}'));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        emit(Unauthenticated());
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        emit(AuthError('Google sign-in failed'));
        return;
      }

      // Check if user document exists, create if not
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'User',
          'email': user.email!,
          'role': 'volunteer',
          'avatarUrl': user.photoURL ?? 'https://i.pravatar.cc/300?u=${user.uid}',
          'skills': [],
          'interests': [],
          'volunteerHistory': [],
          'certificates': [],
          'totalHours': 0,
          'completedActivities': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true, // Google accounts are pre-verified
        });
      }

      final userData = userDoc.exists
          ? userDoc.data()!
          : {'name': user.displayName ?? 'User'};

      emit(Authenticated(
        userId: user.uid,
        email: user.email!,
        name: userData['name'] ?? 'User',
      ));
    } catch (e) {
      emit(AuthError('Google sign-in failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;

      if (user == null) {
        emit(Unauthenticated());
        return;
      }

      // For CheckAuthStatus, we DON'T check email verification
      // This allows users who verified their email to stay logged in
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        emit(Authenticated(
          userId: user.uid,
          email: user.email!,
          name: userData['name'] ?? 'User',
        ));
      } else {
        await _firebaseAuth.signOut();
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }
}