import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/models/volunteer_activity.dart';

// Events
abstract class TrackerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadActivities extends TrackerEvent {}

class ApplyToActivity extends TrackerEvent {
  final String opportunityId;

  ApplyToActivity(this.opportunityId);

  @override
  List<Object?> get props => [opportunityId];
}

class UpdateActivityStatus extends TrackerEvent {
  final String activityId;
  final ActivityStatus newStatus;

  UpdateActivityStatus(this.activityId, this.newStatus);

  @override
  List<Object?> get props => [activityId, newStatus];
}

// States
abstract class TrackerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TrackerInitial extends TrackerState {}

class TrackerLoading extends TrackerState {}

class TrackerLoaded extends TrackerState {
  final List<VolunteerActivity> upcomingActivities;
  final List<VolunteerActivity> pastActivities;

  TrackerLoaded({
    required this.upcomingActivities,
    required this.pastActivities,
  });

  @override
  List<Object?> get props => [upcomingActivities, pastActivities];
}

class TrackerError extends TrackerState {
  final String message;

  TrackerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  List<VolunteerActivity> _allActivities = [];

  TrackerBloc() : super(TrackerInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<ApplyToActivity>(_onApplyToActivity);
    on<UpdateActivityStatus>(_onUpdateActivityStatus);
  }

  Future<void> _onLoadActivities(
      LoadActivities event,
      Emitter<TrackerState> emit,
      ) async {
    emit(TrackerLoading());

    try {
      await Future.delayed(const Duration(seconds: 1));

      _allActivities = _getMockActivities();
      _emitLoadedState(emit);
    } catch (e) {
      emit(TrackerError('Failed to load activities'));
    }
  }

  Future<void> _onApplyToActivity(
      ApplyToActivity event,
      Emitter<TrackerState> emit,
      ) async {
    final newActivity = VolunteerActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Opportunity',
      description: 'Applied opportunity',
      imageUrl: 'https://images.unsplash.com/photo-1559027615-cd4628902d4a',
      status: ActivityStatus.applied,
      date: DateTime.now().add(const Duration(days: 7)),
      progress: 0.0,
    );

    _allActivities.add(newActivity);
    _emitLoadedState(emit);
  }

  Future<void> _onUpdateActivityStatus(
      UpdateActivityStatus event,
      Emitter<TrackerState> emit,
      ) async {
    final index = _allActivities.indexWhere((a) => a.id == event.activityId);
    if (index != -1) {
      _allActivities[index] = _allActivities[index].copyWith(
        status: event.newStatus,
        progress: event.newStatus == ActivityStatus.completed ? 1.0 : _allActivities[index].progress,
      );
      _emitLoadedState(emit);
    }
  }

  void _emitLoadedState(Emitter<TrackerState> emit) {
    final now = DateTime.now();
    final upcoming = _allActivities
        .where((a) =>
    a.status != ActivityStatus.completed &&
        (a.date == null || a.date!.isAfter(now)))
        .toList();

    final past = _allActivities
        .where((a) =>
    a.status == ActivityStatus.completed ||
        (a.date != null && a.date!.isBefore(now)))
        .toList();

    emit(TrackerLoaded(
      upcomingActivities: upcoming,
      pastActivities: past,
    ));
  }

  List<VolunteerActivity> _getMockActivities() {
    return [
      VolunteerActivity(
        id: '1',
        title: 'Food Bank Volunteer',
        description: 'Helping at the local food bank',
        imageUrl: 'https://images.unsplash.com/photo-1593113598332-cd288d649433',
        status: ActivityStatus.applied,
        date: DateTime.now().add(const Duration(days: 5)),
        progress: 0.5,
      ),
      VolunteerActivity(
        id: '2',
        title: 'Community Event Helper',
        description: 'Assisting with event setup',
        imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865',
        status: ActivityStatus.confirmed,
        date: DateTime.now().add(const Duration(days: 10)),
        progress: 0.75,
      ),
      VolunteerActivity(
        id: '3',
        title: 'Library Assistant',
        description: 'Organizing books at the library',
        imageUrl: 'https://images.unsplash.com/photo-1507842217343-583bb7270b66',
        status: ActivityStatus.completed,
        date: DateTime.now().subtract(const Duration(days: 7)),
        progress: 1.0,
      ),
    ];
  }
}