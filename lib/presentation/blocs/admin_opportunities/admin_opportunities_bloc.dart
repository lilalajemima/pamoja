import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/opportunity.dart';
import '../../../core/services/notification_service.dart';

// Events
abstract class AdminOpportunitiesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAdminOpportunities extends AdminOpportunitiesEvent {}

class CreateOpportunity extends AdminOpportunitiesEvent {
  final Opportunity opportunity;

  CreateOpportunity(this.opportunity);

  @override
  List<Object?> get props => [opportunity];
}

class UpdateOpportunity extends AdminOpportunitiesEvent {
  final Opportunity opportunity;

  UpdateOpportunity(this.opportunity);

  @override
  List<Object?> get props => [opportunity];
}

class DeleteOpportunity extends AdminOpportunitiesEvent {
  final String opportunityId;

  DeleteOpportunity(this.opportunityId);

  @override
  List<Object?> get props => [opportunityId];
}

// States
abstract class AdminOpportunitiesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AdminOpportunitiesInitial extends AdminOpportunitiesState {}

class AdminOpportunitiesLoading extends AdminOpportunitiesState {}

class AdminOpportunitiesLoaded extends AdminOpportunitiesState {
  final List<Opportunity> opportunities;

  AdminOpportunitiesLoaded(this.opportunities);

  @override
  List<Object?> get props => [opportunities];
}

class AdminOpportunitiesError extends AdminOpportunitiesState {
  final String message;

  AdminOpportunitiesError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminOpportunityOperationSuccess extends AdminOpportunitiesState {
  final String message;
  final List<Opportunity> opportunities;

  AdminOpportunityOperationSuccess(this.message, this.opportunities);

  @override
  List<Object?> get props => [message, opportunities];
}

// BLoC
class AdminOpportunitiesBloc
    extends Bloc<AdminOpportunitiesEvent, AdminOpportunitiesState> {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  AdminOpportunitiesBloc({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ?? NotificationService(),
        super(AdminOpportunitiesInitial()) {
    on<LoadAdminOpportunities>(_onLoadAdminOpportunities);
    on<CreateOpportunity>(_onCreateOpportunity);
    on<UpdateOpportunity>(_onUpdateOpportunity);
    on<DeleteOpportunity>(_onDeleteOpportunity);
  }

  Future<void> _onLoadAdminOpportunities(
    LoadAdminOpportunities event,
    Emitter<AdminOpportunitiesState> emit,
  ) async {
    emit(AdminOpportunitiesLoading());

    try {
      final querySnapshot = await _firestore
          .collection('opportunities')
          .orderBy('title')
          .get();

      final opportunities = querySnapshot.docs
          .map((doc) => Opportunity.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      emit(AdminOpportunitiesLoaded(opportunities));
    } catch (e) {
      emit(AdminOpportunitiesError('Failed to load opportunities: ${e.toString()}'));
    }
  }

  Future<void> _onCreateOpportunity(
    CreateOpportunity event,
    Emitter<AdminOpportunitiesState> emit,
  ) async {
    emit(AdminOpportunitiesLoading());

    try {
      // Create a new document with auto-generated ID
      final docRef = await _firestore.collection('opportunities').add({
        'title': event.opportunity.title,
        'description': event.opportunity.description,
        'category': event.opportunity.category,
        'location': event.opportunity.location,
        'timeCommitment': event.opportunity.timeCommitment,
        'requirements': event.opportunity.requirements,
        'imageUrl': event.opportunity.imageUrl,
        'date': event.opportunity.date?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('📢 Opportunity created with ID: ${docRef.id}');
      print('📢 Sending notifications to all users...');

      // Send notification to all users about new opportunity
      await _notificationService.notifyNewOpportunity(
        opportunityTitle: event.opportunity.title,
        opportunityId: docRef.id,
        imageUrl: event.opportunity.imageUrl,
      );

      print('✅ Notifications sent successfully!');

      // Reload opportunities
      final querySnapshot = await _firestore
          .collection('opportunities')
          .orderBy('title')
          .get();

      final opportunities = querySnapshot.docs
          .map((doc) => Opportunity.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      emit(AdminOpportunityOperationSuccess(
        'Opportunity created successfully',
        opportunities,
      ));
    } catch (e) {
      print('❌ Error creating opportunity: $e');
      emit(AdminOpportunitiesError('Failed to create opportunity: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOpportunity(
    UpdateOpportunity event,
    Emitter<AdminOpportunitiesState> emit,
  ) async {
    emit(AdminOpportunitiesLoading());

    try {
      await _firestore.collection('opportunities').doc(event.opportunity.id).update({
        'title': event.opportunity.title,
        'description': event.opportunity.description,
        'category': event.opportunity.category,
        'location': event.opportunity.location,
        'timeCommitment': event.opportunity.timeCommitment,
        'requirements': event.opportunity.requirements,
        'imageUrl': event.opportunity.imageUrl,
        'date': event.opportunity.date?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reload opportunities
      final querySnapshot = await _firestore
          .collection('opportunities')
          .orderBy('title')
          .get();

      final opportunities = querySnapshot.docs
          .map((doc) => Opportunity.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      emit(AdminOpportunityOperationSuccess(
        'Opportunity updated successfully',
        opportunities,
      ));
    } catch (e) {
      emit(AdminOpportunitiesError('Failed to update opportunity: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteOpportunity(
    DeleteOpportunity event,
    Emitter<AdminOpportunitiesState> emit,
  ) async {
    emit(AdminOpportunitiesLoading());

    try {
      await _firestore.collection('opportunities').doc(event.opportunityId).delete();

      // Reload opportunities
      final querySnapshot = await _firestore
          .collection('opportunities')
          .orderBy('title')
          .get();

      final opportunities = querySnapshot.docs
          .map((doc) => Opportunity.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();

      emit(AdminOpportunityOperationSuccess(
        'Opportunity deleted successfully',
        opportunities,
      ));
    } catch (e) {
      emit(AdminOpportunitiesError('Failed to delete opportunity: ${e.toString()}'));
    }
  }
}