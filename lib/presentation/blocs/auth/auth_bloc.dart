import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class FacebookSignInRequested extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

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

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SharedPreferences prefs;

  AuthBloc(this.prefs) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<FacebookSignInRequested>(_onFacebookSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo purposes - accept any email/password
      if (event.email.isNotEmpty && event.password.isNotEmpty) {
        await prefs.setString('userId', 'user_123');
        await prefs.setString('email', event.email);
        await prefs.setString('name', 'Demo User');
        await prefs.setBool('isLoggedIn', true);

        emit(Authenticated(
          userId: 'user_123',
          email: event.email,
          name: 'Demo User',
        ));
      } else {
        emit(AuthError('Invalid credentials'));
      }
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onSignupRequested(
      SignupRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (event.email.isNotEmpty &&
          event.password.isNotEmpty &&
          event.name.isNotEmpty) {
        await prefs.setString('userId', 'user_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('email', event.email);
        await prefs.setString('name', event.name);
        await prefs.setBool('isLoggedIn', true);

        emit(Authenticated(
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: event.email,
          name: event.name,
        ));
      } else {
        emit(AuthError('All fields are required'));
      }
    } catch (e) {
      emit(AuthError('Signup failed: ${e.toString()}'));
    }
  }

  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      await Future.delayed(const Duration(seconds: 2));

      await prefs.setString('userId', 'google_user_123');
      await prefs.setString('email', 'user@gmail.com');
      await prefs.setString('name', 'Google User');
      await prefs.setBool('isLoggedIn', true);

      emit(Authenticated(
        userId: 'google_user_123',
        email: 'user@gmail.com',
        name: 'Google User',
      ));
    } catch (e) {
      emit(AuthError('Google sign-in failed: ${e.toString()}'));
    }
  }

  Future<void> _onFacebookSignInRequested(
      FacebookSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      await Future.delayed(const Duration(seconds: 2));

      await prefs.setString('userId', 'fb_user_123');
      await prefs.setString('email', 'user@facebook.com');
      await prefs.setString('name', 'Facebook User');
      await prefs.setBool('isLoggedIn', true);

      emit(Authenticated(
        userId: 'fb_user_123',
        email: 'user@facebook.com',
        name: 'Facebook User',
      ));
    } catch (e) {
      emit(AuthError('Facebook sign-in failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    await prefs.clear();
    emit(Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userId = prefs.getString('userId') ?? '';
      final email = prefs.getString('email') ?? '';
      final name = prefs.getString('name') ?? '';

      emit(Authenticated(userId: userId, email: email, name: name));
    } else {
      emit(Unauthenticated());
    }
  }
}