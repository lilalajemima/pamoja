import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/models/opportunity.dart';

// Events
abstract class OpportunitiesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadOpportunities extends OpportunitiesEvent {}

class FilterOpportunities extends OpportunitiesEvent {
  final String category;

  FilterOpportunities(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchOpportunities extends OpportunitiesEvent {
  final String query;

  SearchOpportunities(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleSaveOpportunity extends OpportunitiesEvent {
  final String opportunityId;

  ToggleSaveOpportunity(this.opportunityId);

  @override
  List<Object?> get props => [opportunityId];
}

// States
abstract class OpportunitiesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OpportunitiesInitial extends OpportunitiesState {}

class OpportunitiesLoading extends OpportunitiesState {}

class OpportunitiesLoaded extends OpportunitiesState {
  final List<Opportunity> opportunities;
  final String? selectedCategory;
  final Set<String> savedOpportunityIds;

  OpportunitiesLoaded({
    required this.opportunities,
    this.selectedCategory,
    this.savedOpportunityIds = const {},
  });

  @override
  List<Object?> get props => [opportunities, selectedCategory, savedOpportunityIds];

  OpportunitiesLoaded copyWith({
    List<Opportunity>? opportunities,
    String? selectedCategory,
    Set<String>? savedOpportunityIds,
  }) {
    return OpportunitiesLoaded(
      opportunities: opportunities ?? this.opportunities,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      savedOpportunityIds: savedOpportunityIds ?? this.savedOpportunityIds,
    );
  }
}

class OpportunitiesError extends OpportunitiesState {
  final String message;

  OpportunitiesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class OpportunitiesBloc extends Bloc<OpportunitiesEvent, OpportunitiesState> {
  List<Opportunity> _allOpportunities = [];
  Set<String> _savedIds = {};

  OpportunitiesBloc() : super(OpportunitiesInitial()) {
    on<LoadOpportunities>(_onLoadOpportunities);
    on<FilterOpportunities>(_onFilterOpportunities);
    on<SearchOpportunities>(_onSearchOpportunities);
    on<ToggleSaveOpportunity>(_onToggleSaveOpportunity);
  }

  Future<void> _onLoadOpportunities(
      LoadOpportunities event,
      Emitter<OpportunitiesState> emit,
      ) async {
    emit(OpportunitiesLoading());

    try {
      await Future.delayed(const Duration(seconds: 1));

      _allOpportunities = _getMockOpportunities();

      emit(OpportunitiesLoaded(
        opportunities: _allOpportunities,
        savedOpportunityIds: _savedIds,
      ));
    } catch (e) {
      emit(OpportunitiesError('Failed to load opportunities'));
    }
  }

  Future<void> _onFilterOpportunities(
      FilterOpportunities event,
      Emitter<OpportunitiesState> emit,
      ) async {
    if (state is OpportunitiesLoaded) {
      final currentState = state as OpportunitiesLoaded;

      final filtered = event.category.isEmpty
          ? _allOpportunities
          : _allOpportunities
          .where((o) => o.category.toLowerCase() == event.category.toLowerCase())
          .toList();

      emit(currentState.copyWith(
        opportunities: filtered,
        selectedCategory: event.category.isEmpty ? null : event.category,
      ));
    }
  }

  Future<void> _onSearchOpportunities(
      SearchOpportunities event,
      Emitter<OpportunitiesState> emit,
      ) async {
    if (state is OpportunitiesLoaded) {
      final currentState = state as OpportunitiesLoaded;

      final filtered = event.query.isEmpty
          ? _allOpportunities
          : _allOpportunities
          .where((o) =>
      o.title.toLowerCase().contains(event.query.toLowerCase()) ||
          o.description.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

      emit(currentState.copyWith(opportunities: filtered));
    }
  }

  Future<void> _onToggleSaveOpportunity(
      ToggleSaveOpportunity event,
      Emitter<OpportunitiesState> emit,
      ) async {
    if (state is OpportunitiesLoaded) {
      final currentState = state as OpportunitiesLoaded;

      if (_savedIds.contains(event.opportunityId)) {
        _savedIds.remove(event.opportunityId);
      } else {
        _savedIds.add(event.opportunityId);
      }

      emit(currentState.copyWith(savedOpportunityIds: Set.from(_savedIds)));
    }
  }

  List<Opportunity> _getMockOpportunities() {
    return [
      Opportunity(
        id: '1',
        title: 'Community Garden Assistant',
        description: 'Help plant trees in the local park. Saturday, 9AM-12PM',
        category: 'Environment',
        location: 'Central Park Community Garden',
        timeCommitment: '2 hours/week',
        requirements: 'Age 16+ Enthusiasm',
        imageUrl: 'https://images.unsplash.com/photo-1591189863430-ab87e120f312',
      ),
      Opportunity(
        id: '2',
        title: 'After-School Tutoring',
        description: 'Assist students with homework. Tuesdays & Thursdays, 4 PM-6 PM',
        category: 'Education',
        location: 'Local Community Center',
        timeCommitment: '4 hours/week',
        requirements: 'Teaching experience preferred',
        imageUrl: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b',
      ),
      Opportunity(
        id: '3',
        title: 'Blood Drive Volunteer',
        description: 'Support a local blood drive. Next Sunday, 10AM-3PM',
        category: 'Health',
        location: 'City Hospital',
        timeCommitment: '5 hours',
        requirements: 'Age 18+',
        imageUrl: 'https://images.unsplash.com/photo-1615461066159-fea0960485d5',
      ),
      Opportunity(
        id: '4',
        title: 'Animal Shelter Helper',
        description: 'Care for animals and help with daily tasks',
        category: 'Animals',
        location: 'Local Animal Shelter',
        timeCommitment: '3 hours/week',
        requirements: 'Love for animals',
        imageUrl: 'https://images.unsplash.com/photo-1450778869180-41d0601e046e',
      ),
      Opportunity(
        id: '5',
        title: 'Arts Festival Assistant',
        description: 'Help organize and run community arts festival',
        category: 'Arts & Culture',
        location: 'Downtown Arts Center',
        timeCommitment: '6 hours',
        requirements: 'Creative mindset',
        imageUrl: 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b',
      ),
    ];
  }
}