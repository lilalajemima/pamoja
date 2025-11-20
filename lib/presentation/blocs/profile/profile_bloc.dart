import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/user_profile.dart';

// Events
abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final UserProfile profile;

  UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AddSkill extends ProfileEvent {
  final String skill;

  AddSkill(this.skill);

  @override
  List<Object?> get props => [skill];
}

class RemoveSkill extends ProfileEvent {
  final String skill;

  RemoveSkill(this.skill);

  @override
  List<Object?> get props => [skill];
}

class AddInterest extends ProfileEvent {
  final String interest;

  AddInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

class RemoveInterest extends ProfileEvent {
  final String interest;

  RemoveInterest(this.interest);

  @override
  List<Object?> get props => [interest];
}

// States
abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ProfileBloc({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<AddSkill>(_onAddSkill);
    on<RemoveSkill>(_onRemoveSkill);
    on<AddInterest>(_onAddInterest);
    on<RemoveInterest>(_onRemoveInterest);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        emit(ProfileError('No user logged in'));
        return;
      }

      // Get user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        emit(ProfileError('Profile not found'));
        return;
      }

      final data = userDoc.data()!;

      final profile = UserProfile(
        id: user.uid,
        name: data['name'] ?? 'User',
        email: data['email'] ?? user.email ?? '',
        avatarUrl: data['avatarUrl'] ?? 'https://i.pravatar.cc/300?u=${user.uid}',
        role: data['role'] ?? 'volunteer',
        skills: List<String>.from(data['skills'] ?? []),
        interests: List<String>.from(data['interests'] ?? []),
        volunteerHistory: data['volunteerHistory'] != null
            ? (data['volunteerHistory'] as List)
                .map((item) => Map<String, String>.from(item as Map))
                .toList()
            : [],
        certificates: List<String>.from(data['certificates'] ?? []),
        totalHours: data['totalHours'] ?? 0,
        completedActivities: data['completedActivities'] ?? 0,
      );

      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        emit(ProfileError('No user logged in'));
        return;
      }

      // Update profile in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': event.profile.name,
        'avatarUrl': event.profile.avatarUrl,
        'skills': event.profile.skills,
        'interests': event.profile.interests,
        'volunteerHistory': event.profile.volunteerHistory,
        'certificates': event.profile.certificates,
        'totalHours': event.profile.totalHours,
        'completedActivities': event.profile.completedActivities,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      emit(ProfileLoaded(event.profile));
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _onAddSkill(AddSkill event, Emitter<ProfileState> emit) async {
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedSkills = List<String>.from(currentProfile.skills)
          ..add(event.skill);

        // Update in Firestore
        await _firestore.collection('users').doc(currentProfile.id).update({
          'skills': updatedSkills,
        });

        emit(ProfileLoaded(currentProfile.copyWith(skills: updatedSkills)));
      } catch (e) {
        emit(ProfileError('Failed to add skill: ${e.toString()}'));
        // Reload profile to recover
        add(LoadProfile());
      }
    }
  }

  Future<void> _onRemoveSkill(
    RemoveSkill event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedSkills = List<String>.from(currentProfile.skills)
          ..remove(event.skill);

        // Update in Firestore
        await _firestore.collection('users').doc(currentProfile.id).update({
          'skills': updatedSkills,
        });

        emit(ProfileLoaded(currentProfile.copyWith(skills: updatedSkills)));
      } catch (e) {
        emit(ProfileError('Failed to remove skill: ${e.toString()}'));
        add(LoadProfile());
      }
    }
  }

  Future<void> _onAddInterest(
    AddInterest event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedInterests = List<String>.from(currentProfile.interests)
          ..add(event.interest);

        // Update in Firestore
        await _firestore.collection('users').doc(currentProfile.id).update({
          'interests': updatedInterests,
        });

        emit(ProfileLoaded(
            currentProfile.copyWith(interests: updatedInterests)));
      } catch (e) {
        emit(ProfileError('Failed to add interest: ${e.toString()}'));
        add(LoadProfile());
      }
    }
  }

  Future<void> _onRemoveInterest(
    RemoveInterest event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedInterests = List<String>.from(currentProfile.interests)
          ..remove(event.interest);

        // Update in Firestore
        await _firestore.collection('users').doc(currentProfile.id).update({
          'interests': updatedInterests,
        });

        emit(ProfileLoaded(
            currentProfile.copyWith(interests: updatedInterests)));
      } catch (e) {
        emit(ProfileError('Failed to remove interest: ${e.toString()}'));
        add(LoadProfile());
      }
    }
  }
}