import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/opportunities/opportunities_bloc.dart';
import '../../widgets/opportunity_card.dart';
import '../../widgets/category_chip.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
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
    context.read<OpportunitiesBloc>().add(LoadOpportunities());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search opportunities...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.mediumGray),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.mediumGray),
                  onPressed: () {
                    _searchController.clear();
                    context.read<OpportunitiesBloc>().add(
                      SearchOpportunities(''),
                    );
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                context.read<OpportunitiesBloc>().add(
                  SearchOpportunities(value),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<OpportunitiesBloc>().add(
                              LoadOpportunities(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: Theme.of(context).textTheme.bodyMedium,
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
                          context.push('/opportunity/${opportunity.id}');
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
    _searchController.dispose();
    super.dispose();
  }
}