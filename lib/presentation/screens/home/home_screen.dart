import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/opportunities/opportunities_bloc.dart';
import '../../widgets/opportunity_card.dart';
import '../../widgets/category_chip.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pamoja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Your Feed',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.mediumGray,
            indicatorColor: AppTheme.primaryGreen,
            tabs: const [
              Tab(text: 'Recommended'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Saved'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(context).textTheme.headlineMedium,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Opportunities Near You',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
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
                        Icon(Icons.error_outline,
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
                          Icon(Icons.search_off,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayOpportunities.length,
                      itemBuilder: (context, index) {
                        final opportunity = displayOpportunities[index];
                        final isSaved = state.savedOpportunityIds
                            .contains(opportunity.id);

                        return OpportunityCard(
                          opportunity: opportunity,
                          isSaved: isSaved,
                          onTap: () {
                            // Navigate to detail screen
                            context.push('/opportunity/${opportunity.id}');
                          },
                          onSaveToggle: () {
                            // Toggle save state
                            context.read<OpportunitiesBloc>().add(
                              ToggleSaveOpportunity(opportunity.id),
                            );
                            
                            // Show feedback
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