import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                  if (state.opportunities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: AppTheme.mediumGray),
                          const SizedBox(height: 16),
                          Text(
                            'No opportunities found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.opportunities.length,
                    itemBuilder: (context, index) {
                      final opportunity = state.opportunities[index];
                      final isSaved = state.savedOpportunityIds
                          .contains(opportunity.id);

                      return OpportunityCard(
                        opportunity: opportunity,
                        isSaved: isSaved,
                        onTap: () {
                          // Navigate to detail screen
                        },
                        onSaveToggle: () {
                          context.read<OpportunitiesBloc>().add(
                            ToggleSaveOpportunity(opportunity.id),
                          );
                        },
                      );
                    },
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