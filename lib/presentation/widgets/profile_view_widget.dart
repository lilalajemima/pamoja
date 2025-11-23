import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/user_profile.dart';
import '../widgets/skill_chip.dart';

class ProfileViewWidget extends StatelessWidget {
  final UserProfile profile;
  final bool showEditButton;

  const ProfileViewWidget({
    super.key,
    required this.profile,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Section
          Container(
            color: AppTheme.lightGray,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.lightGreen,
                  backgroundImage: profile.avatarUrl.startsWith('data:image')
                      ? MemoryImage(
                          base64Decode(profile.avatarUrl.split(',')[1]),
                        )
                      : CachedNetworkImageProvider(profile.avatarUrl) as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.role,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Skills Section
          if (profile.skills.isNotEmpty)
            _buildSection(
              context: context,
              title: 'Skills',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.skills.map((skill) {
                    return SkillChip(
                      label: skill,
                      onDelete: null, // No delete for view-only
                    );
                  }).toList(),
                ),
              ),
            ),
          
          if (profile.skills.isNotEmpty) const SizedBox(height: 16),
          
          // Interests Section
          if (profile.interests.isNotEmpty)
            _buildSection(
              context: context,
              title: 'Interests',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests.map((interest) {
                    return SkillChip(
                      label: interest,
                      onDelete: null, // No delete for view-only
                    );
                  }).toList(),
                ),
              ),
            ),
          
          if (profile.interests.isNotEmpty) const SizedBox(height: 16),
          
          // Volunteering History Section
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getVolunteeringHistory(profile.id),
            builder: (context, snapshot) {
              final autoHistory = snapshot.data ?? [];
              final manualHistory = profile.volunteerHistory;
              final allHistory = [...autoHistory, ...manualHistory];

              if (allHistory.isEmpty) return const SizedBox();

              return Column(
                children: [
                  _buildSection(
                    context: context,
                    title: 'Volunteering History',
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: allHistory.length,
                      itemBuilder: (context, index) {
                        final history = allHistory[index];
                        final bool hasImage = history['imageUrl'] != null && history['imageUrl'].toString().isNotEmpty;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              hasImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: history['imageUrl'],
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightGreen,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: history['icon'] != null
                                                ? Text(
                                                    history['icon'],
                                                    style: const TextStyle(fontSize: 24),
                                                  )
                                                : const Icon(
                                                    Icons.volunteer_activism,
                                                    color: AppTheme.primaryGreen,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: history['icon'] != null
                                            ? Text(
                                                history['icon'],
                                                style: const TextStyle(fontSize: 24),
                                              )
                                            : const Icon(
                                                Icons.volunteer_activism,
                                                color: AppTheme.primaryGreen,
                                              ),
                                      ),
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      history['title'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      history['subtitle'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: AppTheme.mediumGray),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
          
          // Certificates Section
          if (profile.certificates.isNotEmpty)
            _buildSection(
              context: context,
              title: 'Certificates',
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  itemCount: profile.certificates.length,
                  itemBuilder: (context, index) {
                    final cert = profile.certificates[index];
                    
                    if (cert.startsWith('data:text/pdf')) {
                      final name = cert.split(',')[1];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGreen),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              size: 64,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: cert.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(cert.split(',')[1]),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                cert,
                                fit: BoxFit.cover,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getVolunteeringHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'imageUrl': data['imageUrl'] ?? '',
          'title': data['opportunityTitle'] ?? 'Volunteer Activity',
          'subtitle': 'Completed',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}