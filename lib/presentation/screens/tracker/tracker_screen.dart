import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/tracker/tracker_bloc.dart';
import '../../../domain/models/volunteer_activity.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TrackerBloc>().add(LoadActivities());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('Tracker'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.primaryGreen,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<TrackerBloc, TrackerState>(
        listener: (context, state) {
          if (state is TrackerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TrackerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TrackerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: AppTheme.mediumGray),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TrackerBloc>().add(LoadActivities());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final upcomingActivities = state is TrackerLoaded
              ? state.upcomingActivities
              : state is TrackerOperationSuccess
                  ? state.upcomingActivities
                  : [];

          final pastActivities = state is TrackerLoaded
              ? state.pastActivities
              : state is TrackerOperationSuccess
                  ? state.pastActivities
                  : [];

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TrackerBloc>().add(LoadActivities());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upcoming Section
                    Text(
                      'Upcoming',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (upcomingActivities.isEmpty)
                      _buildEmptyState(
                        icon: Icons.event_busy,
                        message: 'No upcoming activities',
                      )
                    else
                      ...upcomingActivities.map((activity) {
                        return _ActivityCard(
                          activity: activity,
                          onTap: () => _showActivityDetails(context, activity),
                        );
                      }).toList(),
                    const SizedBox(height: 32),
                    
                    // Past Section
                    Text(
                      'Past',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (pastActivities.isEmpty)
                      _buildEmptyState(
                        icon: Icons.history,
                        message: 'No past activities',
                      )
                    else
                      ...pastActivities.map((activity) {
                        return _ActivityCard(
                          activity: activity,
                          onTap: () => _showActivityDetails(context, activity),
                        );
                      }).toList(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppTheme.mediumGray),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.mediumGray,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, VolunteerActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ActivityDetailsSheet(activity: activity),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final VolunteerActivity activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Activity Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: activity.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.lightGray,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.lightGray,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Activity Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar and Status
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: activity.progressValue,
                      backgroundColor: AppTheme.lightGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGreen,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(activity.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.statusLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(activity.status),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.applied:
        return Colors.orange;
      case ActivityStatus.confirmed:
        return AppTheme.primaryGreen;
      case ActivityStatus.completed:
        return Colors.blue;
      case ActivityStatus.rejected:
        return Colors.red;
    }
  }
}

class _ActivityDetailsSheet extends StatelessWidget {
  final VolunteerActivity activity;

  const _ActivityDetailsSheet({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: activity.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    activity.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    activity.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.mediumGray,
                        ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Progress Steps
                  _buildProgressSteps(context, activity),
                  const SizedBox(height: 24),
                  
                  // Status Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(activity.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activity.statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(BuildContext context, VolunteerActivity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStep(
              context,
              number: 1,
              label: 'Applied',
              isActive: activity.currentStep >= 1,
              isCompleted: activity.currentStep > 1,
            ),
            _buildConnector(isActive: activity.currentStep >= 2),
            _buildStep(
              context,
              number: 2,
              label: 'Confirmed',
              isActive: activity.currentStep >= 2,
              isCompleted: activity.currentStep > 2,
            ),
            _buildConnector(isActive: activity.currentStep >= 3),
            _buildStep(
              context,
              number: 3,
              label: 'Completed',
              isActive: activity.currentStep >= 3,
              isCompleted: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int number,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryGreen : AppTheme.lightGray,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.mediumGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppTheme.primaryGreen : AppTheme.mediumGray,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isActive ? AppTheme.primaryGreen : AppTheme.lightGray,
      ),
    );
  }

  Color _getStatusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.applied:
        return Colors.orange;
      case ActivityStatus.confirmed:
        return AppTheme.primaryGreen;
      case ActivityStatus.completed:
        return Colors.blue;
      case ActivityStatus.rejected:
        return Colors.red;
    }
  }
}