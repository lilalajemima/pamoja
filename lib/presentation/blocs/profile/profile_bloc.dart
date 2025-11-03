import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
  ProfileBloc() : super(ProfileInitial()) {
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
      await Future.delayed(const Duration(seconds: 1));

      final profile = _getMockProfile();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Failed to load profile'));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfile event,
      Emitter<ProfileState> emit,
      ) async {
    emit(ProfileLoaded(event.profile));
  }

  Future<void> _onAddSkill(
      AddSkill event,
      Emitter<ProfileState> emit,
      ) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedSkills = List<String>.from(currentProfile.skills)..add(event.skill);
      emit(ProfileLoaded(currentProfile.copyWith(skills: updatedSkills)));
    }
  }

  Future<void> _onRemoveSkill(
      RemoveSkill event,
      Emitter<ProfileState> emit,
      ) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedSkills = List<String>.from(currentProfile.skills)..remove(event.skill);
      emit(ProfileLoaded(currentProfile.copyWith(skills: updatedSkills)));
    }
  }

  Future<void> _onAddInterest(
      AddInterest event,
      Emitter<ProfileState> emit,
      ) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedInterests = List<String>.from(currentProfile.interests)..add(event.interest);
      emit(ProfileLoaded(currentProfile.copyWith(interests: updatedInterests)));
    }
  }

  Future<void> _onRemoveInterest(
      RemoveInterest event,
      Emitter<ProfileState> emit,
      ) async {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedInterests = List<String>.from(currentProfile.interests)..remove(event.interest);
      emit(ProfileLoaded(currentProfile.copyWith(interests: updatedInterests)));
    }
  }

  UserProfile _getMockProfile() {
    return const UserProfile(
      id: 'user_123',
      name: 'Aisha Hassan',
      email: 'aisha.hassan@example.com',
      avatarUrl: 'https://i.pravatar.cc/300?img=5',
      role: 'Volunteer',
      skills: [
        'Event Planning',
        'social Media',
        'First Aid',
        'Teaching',
      ],
      interests: [
        'Environment',
        'Education',
        'Health',
        'Arts',
      ],
      volunteerHistory: [
        {
          'title': 'Green Earth Initiative',
          'subtitle': 'Community Cleanup',
          'icon': '🌍',
        },
        {
          'title': 'Youth Empowerment Program',
          'subtitle': 'Tutoring and Skill',
          'icon': '📚',
        },
      ],
      certificates: [
        'https://via.placeholder.com/300x200/4A5568/FFFFFF?text=Certificate+1',
        'https://via.placeholder.com/300x200/4A5568/FFFFFF?text=Certificate+2',
      ],
      totalHours: 48,
      completedActivities: 12,
    );
  }
}