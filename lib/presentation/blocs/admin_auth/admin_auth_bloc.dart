import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Events
abstract class AdminAuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminLoginRequested extends AdminAuthEvent {
  final String email;
  final String password;

  AdminLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AdminLogoutRequested extends AdminAuthEvent {}

class CheckAdminStatus extends AdminAuthEvent {}

// States
abstract class AdminAuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {}

class AdminAuthLoading extends AdminAuthState {}

class AdminAuthenticated extends AdminAuthState {
  final String adminId;
  final String email;

  AdminAuthenticated({required this.adminId, required this.email});

  @override
  List<Object?> get props => [adminId, email];
}

class AdminUnauthenticated extends AdminAuthState {}

class AdminAuthError extends AdminAuthState {
  final String message;

  AdminAuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AdminAuthBloc({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(AdminAuthInitial()) {
    on<AdminLoginRequested>(_onAdminLoginRequested);
    on<AdminLogoutRequested>(_onAdminLogoutRequested);
    on<CheckAdminStatus>(_onCheckAdminStatus);
  }

  Future<void> _onAdminLoginRequested(
    AdminLoginRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(AdminAuthLoading());

    try {
      // Sign in with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      final user = userCredential.user;
      if (user == null) {
        emit(AdminAuthError('Authentication failed'));
        return;
      }

      // Check if user is an admin
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.email)
          .get();

      if (!adminDoc.exists) {
        // Not an admin, sign out
        await _firebaseAuth.signOut();
        emit(AdminAuthError('Access denied. Admin privileges required.'));
        return;
      }

      emit(AdminAuthenticated(
        adminId: user.uid,
        email: user.email!,
      ));
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No admin account found with this email';
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
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      
      emit(AdminAuthError(errorMessage));
    } catch (e) {
      emit(AdminAuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onAdminLogoutRequested(
    AdminLogoutRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    try {
      await _firebaseAuth.signOut();
      emit(AdminUnauthenticated());
    } catch (e) {
      emit(AdminAuthError('Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckAdminStatus(
    CheckAdminStatus event,
    Emitter<AdminAuthState> emit,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;

      if (user == null) {
        emit(AdminUnauthenticated());
        return;
      }

      // Check if user is an admin
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.email)
          .get();

      if (adminDoc.exists) {
        emit(AdminAuthenticated(
          adminId: user.uid,
          email: user.email!,
        ));
      } else {
        await _firebaseAuth.signOut();
        emit(AdminUnauthenticated());
      }
    } catch (e) {
      emit(AdminUnauthenticated());
    }
  }
}