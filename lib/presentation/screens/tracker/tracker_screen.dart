import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../blocs/tracker/tracker_bloc.dart';
import '../../blocs/notifications/notifications_bloc.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Tracker'),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      actions: [
        BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;
            
            return Stack(
              children: [
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
                      context.push('/notifications');
                    },
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 16,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocConsumer<TrackerBloc, TrackerState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        if (state is TrackerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TrackerError) {
          return _buildErrorState(context, state.message);
        }

        return _buildActivitiesList(context, state);
      },
    );
  }

  void _handleStateChanges(BuildContext context, TrackerState state) {
    if (state is TrackerOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          Text(message),
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

  Widget _buildActivitiesList(BuildContext context, TrackerState state) {
    final upcomingActivities = _getUpcomingActivities(state);
    final pastActivities = _getPastActivities(state);

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
              _buildSectionHeader(context, 'Upcoming'),
              const SizedBox(height: 16),
              _buildActivitiesSection(
                context,
                upcomingActivities,
                Icons.event_busy,
                'No upcoming activities',
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Past'),
              const SizedBox(height: 16),
              _buildActivitiesSection(
                context,
                pastActivities,
                Icons.history,
                'No past activities',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<VolunteerActivity> _getUpcomingActivities(TrackerState state) {
    if (state is TrackerLoaded) {
      return state.upcomingActivities;
    } else if (state is TrackerOperationSuccess) {
      return state.upcomingActivities;
    }
    return [];
  }

  List<VolunteerActivity> _getPastActivities(TrackerState state) {
    if (state is TrackerLoaded) {
      return state.pastActivities;
    } else if (state is TrackerOperationSuccess) {
      return state.pastActivities;
    }
    return [];
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildActivitiesSection(
    BuildContext context,
    List<VolunteerActivity> activities,
    IconData emptyIcon,
    String emptyMessage,
  ) {
    if (activities.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: emptyIcon,
        message: emptyMessage,
      );
    }

    return Column(
      children: activities.map((activity) {
        return _ActivityCard(
          activity: activity,
          onTap: () => _showActivityDetails(context, activity),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
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
            _buildCardHeader(context),
            const SizedBox(height: 16),
            _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Row(
      children: [
        _buildActivityImage(context),
        const SizedBox(width: 16),
        _buildActivityInfo(context),
        _buildArrowIcon(),
      ],
    );
  }

  Widget _buildActivityImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildImageWidget(activity.imageUrl, 60, 60, context),
    );
  }

  Widget _buildImageWidget(String imageUrl, double width, double height, BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(width, height);
          },
        );
      } catch (e) {
        return _buildPlaceholder(width, height);
      }
    }
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: AppTheme.lightGray,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(width, height),
    );
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.lightGray,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _buildActivityInfo(BuildContext context) {
    return Expanded(
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
    );
  }

  Widget _buildArrowIcon() {
    return const Icon(
      Icons.arrow_forward_ios,
      size: 16,
      color: AppTheme.primaryGreen,
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: activity.progressValue,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkCard
                  : AppTheme.lightGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusBadge(context),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivityImage(context),
                  const SizedBox(height: 24),
                  _buildTitle(context),
                  const SizedBox(height: 12),
                  _buildDescription(context),
                  const SizedBox(height: 24),
                  _buildProgressSteps(context),
                  const SizedBox(height: 24),
                  _buildStatusContainer(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _buildImageWidget(context),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (activity.imageUrl.startsWith('data:image')) {
      try {
        final base64String = activity.imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          width: double.infinity,
          height: 200,
          color: AppTheme.lightGray,
          child: const Icon(Icons.image_not_supported, size: 48),
        );
      }
    }
    
    return CachedNetworkImage(
      imageUrl: activity.imageUrl,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        height: 200,
        color: AppTheme.lightGray,
        child: const Icon(Icons.image_not_supported, size: 48),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      activity.title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      activity.description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.mediumGray,
          ),
    );
  }

  Widget _buildProgressSteps(BuildContext context) {
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
            _buildConnector(
              context,
              isActive: activity.currentStep >= 2,
            ),
            _buildStep(
              context,
              number: 2,
              label: 'Confirmed',
              isActive: activity.currentStep >= 2,
              isCompleted: activity.currentStep > 2,
            ),
            _buildConnector(
              context,
              isActive: activity.currentStep >= 3,
            ),
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

  Widget _buildConnector(BuildContext context, {required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28),
        color: isActive ? AppTheme.primaryGreen : AppTheme.lightGray,
      ),
    );
  }

  Widget _buildStatusContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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