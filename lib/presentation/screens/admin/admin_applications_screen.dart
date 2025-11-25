import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  String _selectedFilter = 'all'; // all, applied, confirmed, completed, rejected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Applications')),
              const PopupMenuItem(value: 'applied', child: Text('Pending')),
              const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getApplicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.mediumGray),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.mediumGray),
                  const SizedBox(height: 16),
                  Text(
                    'No applications found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              final data = app.data() as Map<String, dynamic>;
              
              return _ApplicationCard(
                applicationId: app.id,
                data: data,
                onViewProfile: () => _showUserProfile(context, data['userId']),
                onConfirm: () => _confirmApplication(app.id),
                onReject: () => _rejectApplication(app.id),
                onComplete: () => _completeApplication(app.id),
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getApplicationsStream() {
    Query query = FirebaseFirestore.instance
        .collection('applications')
        .orderBy('appliedAt', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  void _showUserProfile(BuildContext context, String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User profile not found')),
        );
        return;
      }

      final userData = userDoc.data()!;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
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
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.lightGreen,
                          backgroundImage: userData['avatarUrl'] != null
                              ? CachedNetworkImageProvider(userData['avatarUrl'])
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['name'] ?? 'User',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData['email'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userData['role'] ?? 'Volunteer',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatCard(
                              label: 'Total Hours',
                              value: '${userData['totalHours'] ?? 0}',
                              icon: Icons.access_time,
                            ),
                            _StatCard(
                              label: 'Completed',
                              value: '${userData['completedActivities'] ?? 0}',
                              icon: Icons.check_circle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Skills
                        if (userData['skills'] != null &&
                            (userData['skills'] as List).isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Skills',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (userData['skills'] as List).map((skill) {
                              return Chip(
                                label: Text(skill.toString()),
                                backgroundColor: AppTheme.lightGreen,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Interests
                        if (userData['interests'] != null &&
                            (userData['interests'] as List).isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Interests',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (userData['interests'] as List).map((interest) {
                              return Chip(
                                label: Text(interest.toString()),
                                backgroundColor: AppTheme.lightGreen,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmApplication(String applicationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application confirmed!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectApplication(String applicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: const Text('Are you sure you want to reject this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('applications')
            .doc(applicationId)
            .update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application rejected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _completeApplication(String applicationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: const Text('Are you sure you want to mark this activity as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get application data to update user stats
        final appDoc = await FirebaseFirestore.instance
            .collection('applications')
            .doc(applicationId)
            .get();
            
        final appData = appDoc.data()!;
        
        // Update application status
        await FirebaseFirestore.instance
            .collection('applications')
            .doc(applicationId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Update user stats
        await FirebaseFirestore.instance
            .collection('users')
            .doc(appData['userId'])
            .update({
          'completedActivities': FieldValue.increment(1),
          'totalHours': FieldValue.increment(3), // Add 3 hours per activity
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application marked as completed!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ApplicationCard extends StatelessWidget {
  final String applicationId;
  final Map<String, dynamic> data;
  final VoidCallback onViewProfile;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  const _ApplicationCard({
    required this.applicationId,
    required this.data,
    required this.onViewProfile,
    required this.onConfirm,
    required this.onReject,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'applied';
    final timestamp = data['appliedAt'];
    final date = timestamp is Timestamp
        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onViewProfile,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.lightGreen,
                    backgroundImage: data['userAvatar'] != null
                        ? CachedNetworkImageProvider(data['userAvatar'])
                        : null,
                    child: data['userAvatar'] == null
                        ? const Icon(Icons.person, color: AppTheme.primaryGreen)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onViewProfile,
                        child: Text(
                          data['userName'] ?? 'Unknown User',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['userEmail'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                // FIXED: Added proper base64 and network image handling
                _buildOpportunityImage(data['imageUrl'] ?? ''),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['opportunityTitle'] ?? 'Opportunity',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied on $date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'applied') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'confirmed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // FIXED: New method to properly handle both base64 and network images
  Widget _buildOpportunityImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildErrorWidget();
      }
    }
    
    // It's a network URL
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
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
        errorWidget: (context, url, error) {
          print('Error loading network image: $error');
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: AppTheme.mediumGray,
        size: 30,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'applied':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'confirmed':
        color = AppTheme.primaryGreen;
        label = 'Confirmed';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = AppTheme.mediumGray;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGreen),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}