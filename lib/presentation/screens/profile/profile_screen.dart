import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/skill_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfile());
  }

  Future<void> _uploadProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final profileState = context.read<ProfileBloc>().state;
      if (profileState is! ProfileLoaded) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      context.read<ProfileBloc>().add(
            UpdateProfile(
              profileState.profile.copyWith(avatarUrl: base64Image),
            ),
          );

      setState(() => _isUploadingImage = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadCertificate() async {
    try {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Certificate Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Image'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      );

      if (choice == null) return;

      final profileState = context.read<ProfileBloc>().state;
      if (profileState is! ProfileLoaded) return;

      if (choice == 'image') {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image == null) return;

        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        final updatedCertificates = List<String>.from(profileState.profile.certificates);
        updatedCertificates.add(base64Image);
        
        context.read<ProfileBloc>().add(
          UpdateProfile(profileState.profile.copyWith(certificates: updatedCertificates)),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate added!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else if (choice == 'pdf') {
        final TextEditingController pdfNameController = TextEditingController();
        
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add PDF Certificate'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter certificate name:'),
                const SizedBox(height: 16),
                TextField(
                  controller: pdfNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., First Aid Certification',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add'),
              ),
            ],
          ),
        );

        if (confirmed == true && pdfNameController.text.isNotEmpty) {
          final pdfIndicator = 'data:text/pdf;name,${pdfNameController.text}';
          
          final updatedCertificates = List<String>.from(profileState.profile.certificates);
          updatedCertificates.add(pdfIndicator);
          
          context.read<ProfileBloc>().add(
            UpdateProfile(profileState.profile.copyWith(certificates: updatedCertificates)),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Certificate added!'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add certificate: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppRouter.settings);
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
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
                      context.read<ProfileBloc>().add(LoadProfile());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            _isUploadingImage
                                ? Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppTheme.lightGreen,
                                    backgroundImage: profile.avatarUrl.startsWith('data:image')
                                        ? MemoryImage(
                                            base64Decode(profile.avatarUrl.split(',')[1]),
                                          )
                                        : CachedNetworkImageProvider(profile.avatarUrl) as ImageProvider,
                                  ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingImage ? null : _uploadProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                  _buildSection(
                    context: context,
                    title: 'Skills',
                    onAdd: () => _showAddSkillDialog(context),
                    child: profile.skills.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No skills added yet',
                              style: TextStyle(color: AppTheme.mediumGray),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.skills.map((skill) {
                                return SkillChip(
                                  label: skill,
                                  onDelete: () {
                                    context.read<ProfileBloc>().add(RemoveSkill(skill));
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Interests Section
                  _buildSection(
                    context: context,
                    title: 'Interests',
                    onAdd: () => _showAddInterestDialog(context),
                    child: profile.interests.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No interests added yet',
                              style: TextStyle(color: AppTheme.mediumGray),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.interests.map((interest) {
                                return SkillChip(
                                  label: interest,
                                  onDelete: () {
                                    context.read<ProfileBloc>().add(RemoveInterest(interest));
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Volunteering History Section (Auto + Manual)
                  _buildVolunteeringHistorySection(context, profile),
                  const SizedBox(height: 16),
                  
                  // Certificates Section
                  _buildSection(
                    context: context,
                    title: 'Certificates',
                    onAdd: _uploadCertificate,
                    child: profile.certificates.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No certificates yet',
                              style: TextStyle(color: AppTheme.mediumGray),
                            ),
                          )
                        : SizedBox(
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

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildVolunteeringHistorySection(BuildContext context, profile) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getVolunteeringHistory(),
      builder: (context, snapshot) {
        final autoHistory = snapshot.data ?? [];
        final manualHistory = profile.volunteerHistory;
        final allHistory = [...autoHistory, ...manualHistory];

        return _buildSection(
          context: context,
          title: 'Volunteering History',
          onAdd: () => _showAddHistoryDialog(context, profile),
          child: allHistory.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No volunteer history yet',
                    style: TextStyle(color: AppTheme.mediumGray),
                  ),
                )
              : ListView.builder(
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
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getVolunteeringHistory() async {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: user.userId)
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

  void _showAddSkillDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Skill',
            hintText: 'e.g., Event Planning',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<ProfileBloc>().add(AddSkill(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddInterestDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interest'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Interest',
            hintText: 'e.g., Environment',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<ProfileBloc>().add(AddInterest(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddHistoryDialog(BuildContext context, profile) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    final iconController = TextEditingController(text: '🌟');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Volunteer History'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (emoji)',
                  hintText: '🌟',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Community Garden Project',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: '20 hours volunteered',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final updatedHistory = List<Map<String, String>>.from(profile.volunteerHistory);
                updatedHistory.add({
                  'icon': iconController.text,
                  'title': titleController.text,
                  'subtitle': subtitleController.text,
                });
                context.read<ProfileBloc>().add(
                  UpdateProfile(profile.copyWith(volunteerHistory: updatedHistory)),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}