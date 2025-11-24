import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../blocs/opportunities/opportunities_bloc.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/notification_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = '';

  final List<String> _categories = [
    'Environment',
    'Education',
    'Health',
    'Arts & Culture',
    'Community',
    'Animals',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
    context.read<OpportunitiesBloc>().add(LoadOpportunities());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pamoja'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: const [
          NotificationButton(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Your Feed" heading
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text(
              'Your Feed',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
            ),
          ),
          
          // Tabs
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: isDarkMode ? AppTheme.darkBackground : Colors.white,
              unselectedLabelColor: isDarkMode ? AppTheme.lightText : AppTheme.darkText,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.primaryGreen,
              ),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _tabController.index == 0
                          ? AppTheme.primaryGreen
                          : AppTheme.lightGreen.withValues(alpha: 0.3),
                    ),
                    child: const Text('Recommended'),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _tabController.index == 1
                          ? AppTheme.primaryGreen
                          : AppTheme.lightGreen.withValues(alpha: 0.3),
                    ),
                    child: const Text('Upcoming'),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _tabController.index == 2
                          ? AppTheme.primaryGreen
                          : AppTheme.lightGreen.withValues(alpha: 0.3),
                    ),
                    child: const Text('Saved'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    return CategoryChip(
                      label: category,
                      isSelected: _selectedCategory == category,
                      onTap: () {
                        setState(() {
                          _selectedCategory =
                              _selectedCategory == category ? '' : category;
                        });
                        context.read<OpportunitiesBloc>().add(
                              FilterOpportunities(_selectedCategory),
                            );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // "Opportunities Near You" heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Opportunities Near You',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Opportunities List
          Expanded(
            child: BlocBuilder<OpportunitiesBloc, OpportunitiesState>(
              builder: (context, state) {
                if (state is OpportunitiesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is OpportunitiesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppTheme.mediumGray),
                        const SizedBox(height: 16),
                        Text(state.message),
                      ],
                    ),
                  );
                }

                if (state is OpportunitiesLoaded) {
                  // Filter based on tab selection
                  List<dynamic> displayOpportunities = [];

                  if (_tabController.index == 0) {
                    // Recommended - show all filtered opportunities
                    displayOpportunities = state.opportunities;
                  } else if (_tabController.index == 2) {
                    // Saved - only show saved opportunities
                    displayOpportunities = state.opportunities
                        .where((opp) => state.savedOpportunityIds.contains(opp.id))
                        .toList();
                  } else {
                    // Upcoming - show all for now
                    displayOpportunities = state.opportunities;
                  }

                  if (displayOpportunities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: AppTheme.mediumGray),
                          const SizedBox(height: 16),
                          Text(
                            _tabController.index == 2
                                ? 'No saved opportunities'
                                : 'No opportunities found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (_tabController.index == 2)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Tap the bookmark icon on opportunities to save them',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<OpportunitiesBloc>().add(LoadOpportunities());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayOpportunities.length,
                      itemBuilder: (context, index) {
                        final opportunity = displayOpportunities[index];
                        final isSaved = state.savedOpportunityIds
                            .contains(opportunity.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _OpportunityCompactCard(
                            opportunity: opportunity,
                            isSaved: isSaved,
                            onTap: () {
                              context.push('/opportunity/${opportunity.id}');
                            },
                            onSaveToggle: () {
                              context.read<OpportunitiesBloc>().add(
                                    ToggleSaveOpportunity(opportunity.id),
                                  );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSaved
                                        ? 'Removed from saved'
                                        : 'Saved successfully',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Compact card with proper image loading
class _OpportunityCompactCard extends StatelessWidget {
  final dynamic opportunity;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  const _OpportunityCompactCard({
    required this.opportunity,
    required this.isSaved,
    required this.onTap,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? AppTheme.darkBorder : AppTheme.lightGray,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category badge and bookmark
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      opportunity.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onSaveToggle,
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? AppTheme.primaryGreen : AppTheme.mediumGray,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Image with proper loading
            _buildImageWidget(context, opportunity.imageUrl),
            
            // Title and details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opportunity.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mediumGray,
                          fontSize: 13,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          opportunity.location,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mediumGray,
                                fontSize: 12,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opportunity.timeCommitment,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mediumGray,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, String imageUrl) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Check if it's a base64 image
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
          child: Image.memory(
            bytes,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading base64 image: $error');
              return _buildPlaceholder(context, isDarkMode);
            },
          ),
        );
      } catch (e) {
        print('❌ Error decoding base64 image: $e');
        return _buildPlaceholder(context, isDarkMode);
      }
    }
    
    // It's a network URL
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(12),
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 120,
          width: double.infinity,
          color: isDarkMode ? AppTheme.darkCard : AppTheme.lightGray,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) {
          print('❌ Error loading network image: $error');
          return _buildPlaceholder(context, isDarkMode);
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDarkMode) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : AppTheme.lightGray,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppTheme.mediumGray,
          size: 32,
        ),
      ),
    );
  }
}