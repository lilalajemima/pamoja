import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../blocs/opportunities/opportunities_bloc.dart';
import '../../blocs/tracker/tracker_bloc.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final String opportunityId;

  const OpportunityDetailScreen({
    super.key,
    required this.opportunityId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<OpportunitiesBloc, OpportunitiesState>(
        builder: (context, state) {
          if (state is! OpportunitiesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final opportunity = state.opportunities.firstWhere(
            (o) => o.id == opportunityId,
            orElse: () => state.opportunities.first,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: AppTheme.darkText),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageWidget(opportunity.imageUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          opportunity.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        opportunity.title,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        opportunity.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Details',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'Time Commitment',
                        value: opportunity.timeCommitment,
                      ),
                      const Divider(height: 32),
                      _DetailRow(
                        label: 'Location',
                        value: opportunity.location,
                      ),
                      const Divider(height: 32),
                      _DetailRow(
                        label: 'Requirements',
                        value: opportunity.requirements,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BlocConsumer<TrackerBloc, TrackerState>(
            listener: (context, state) {
              if (state is TrackerOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
                context.pop();
              } else if (state is TrackerError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, trackerState) {
              final opportunitiesState = context.read<OpportunitiesBloc>().state;

              if (opportunitiesState is! OpportunitiesLoaded) {
                return const SizedBox();
              }

              final opportunity = opportunitiesState.opportunities.firstWhere(
                (o) => o.id == opportunityId,
                orElse: () => opportunitiesState.opportunities.first,
              );

              return ElevatedButton(
                onPressed: trackerState is TrackerLoading
                    ? null
                    : () {
                        context.read<TrackerBloc>().add(
                              ApplyToOpportunity(
                                opportunityId: opportunityId,
                                opportunityTitle: opportunity.title,
                                description: opportunity.description,
                                imageUrl: opportunity.imageUrl,
                              ),
                            );
                      },
                child: trackerState is TrackerLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Apply Now'),
              );
            },
          ),
        ),
      ),
    );
  }

  // Safe image widget builder
  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        // Extract the base64 part after the comma
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildErrorWidget();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildErrorWidget();
      }
    }
    
    // It's a network URL
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.lightGray,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) {
        print('Error loading network image: $error');
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: AppTheme.lightGray,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            SizedBox(height: 16),
            Text(
              'Image not available',
              style: TextStyle(color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.mediumGray,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}