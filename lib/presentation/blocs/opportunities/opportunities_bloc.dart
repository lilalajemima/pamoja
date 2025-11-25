import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    bool clearCategory = false,
    Set<String>? savedOpportunityIds,
  }) {
    return OpportunitiesLoaded(
      opportunities: opportunities ?? this.opportunities,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
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
  final FirebaseFirestore _firestore;
  List<Opportunity> _allOpportunities = [];
  Set<String> _savedIds = {};

  OpportunitiesBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(OpportunitiesInitial()) {
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
      // Load opportunities from Firestore
      final querySnapshot = await _firestore
          .collection('opportunities')
          .orderBy('title')
          .get();

      _allOpportunities = querySnapshot.docs
          .map((doc) => Opportunity.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      emit(OpportunitiesLoaded(
        opportunities: _allOpportunities,
        savedOpportunityIds: _savedIds,
      ));
    } catch (e) {
      emit(OpportunitiesError('Failed to load opportunities: ${e.toString()}'));
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
        selectedCategory: event.category,
        clearCategory: event.category.isEmpty,
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
}