import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/filter_bottom_sheet.dart';

/// Advanced examples and patterns for using FilterBottomSheet
///
/// This file contains real-world usage patterns and advanced scenarios
class AdvancedFilterExamples {
  /// Example 1: Gym/Fitness App Filter
  /// Shows how to structure filters for a fitness facility app
  static FilterExample gymFilterExample() {
    return FilterExample(
      title: 'Gym Facilities Filter',
      categories: [
        FilterCategory(
          name: 'Zones',
          options: [
            FilterOption(name: 'Zone 1 - Cardio', id: 'zone_cardio'),
            FilterOption(name: 'Zone 2 - Weights', id: 'zone_weights'),
            FilterOption(name: 'Zone 3 - CrossFit', id: 'zone_crossfit'),
            FilterOption(name: 'Zone 4 - Yoga', id: 'zone_yoga'),
          ],
        ),
        FilterCategory(
          name: 'Type',
          options: [
            FilterOption(name: 'Reception', id: 'type_reception'),
            FilterOption(name: 'Fitness', id: 'type_fitness'),
            FilterOption(name: 'Cardio', id: 'type_cardio'),
            FilterOption(name: 'Weights', id: 'type_weights'),
            FilterOption(name: 'Stretching', id: 'type_stretching'),
          ],
        ),
        FilterCategory(
          name: 'Features',
          options: [
            FilterOption(name: 'Studio Platinum', id: 'feature_platinum'),
            FilterOption(name: 'Equipment location', id: 'feature_equipment'),
            FilterOption(name: 'Water Cooler', id: 'feature_water'),
            FilterOption(name: 'Locker Room', id: 'feature_lockers'),
          ],
        ),
      ],
    );
  }

  /// Example 2: E-Commerce Product Filter
  /// Shows filters for an online shopping app
  static FilterExample ecommerceFilterExample() {
    return FilterExample(
      title: 'Product Filter',
      categories: [
        FilterCategory(
          name: 'Category',
          options: [
            FilterOption(name: 'Electronics', id: 'cat_electronics'),
            FilterOption(name: 'Clothing', id: 'cat_clothing'),
            FilterOption(name: 'Books', id: 'cat_books'),
            FilterOption(name: 'Home & Garden', id: 'cat_home'),
          ],
        ),
        FilterCategory(
          name: 'Price',
          options: [
            FilterOption(name: 'Under 50 USD', id: 'price_50'),
            FilterOption(name: '50 - 100 USD', id: 'price_50_100'),
            FilterOption(name: '100 - 500 USD', id: 'price_100_500'),
            FilterOption(name: 'Over 500 USD', id: 'price_500'),
          ],
        ),
        FilterCategory(
          name: 'Rating',
          options: [
            FilterOption(name: '5 Stars', id: 'rating_5'),
            FilterOption(name: '4+ Stars', id: 'rating_4'),
            FilterOption(name: '3+ Stars', id: 'rating_3'),
          ],
        ),
        FilterCategory(
          name: 'Availability',
          options: [
            FilterOption(name: 'In Stock', id: 'avail_instock'),
            FilterOption(name: 'Pre-order', id: 'avail_preorder'),
            FilterOption(name: 'Out of Stock', id: 'avail_outofstock'),
          ],
        ),
      ],
    );
  }

  /// Example 3: Real Estate Property Filter
  static FilterExample realEstateFilterExample() {
    return FilterExample(
      title: 'Property Filter',
      categories: [
        FilterCategory(
          name: 'Type',
          options: [
            FilterOption(name: 'House', id: 'type_house'),
            FilterOption(name: 'Apartment', id: 'type_apartment'),
            FilterOption(name: 'Condo', id: 'type_condo'),
            FilterOption(name: 'Townhouse', id: 'type_townhouse'),
            FilterOption(name: 'Land', id: 'type_land'),
          ],
        ),
        FilterCategory(
          name: 'Bedrooms',
          options: [
            FilterOption(name: '1 Bedroom', id: 'bed_1'),
            FilterOption(name: '2 Bedrooms', id: 'bed_2'),
            FilterOption(name: '3 Bedrooms', id: 'bed_3'),
            FilterOption(name: '4+ Bedrooms', id: 'bed_4plus'),
          ],
        ),
        FilterCategory(
          name: 'Amenities',
          options: [
            FilterOption(name: 'Swimming Pool', id: 'amen_pool'),
            FilterOption(name: 'Garage', id: 'amen_garage'),
            FilterOption(name: 'Garden', id: 'amen_garden'),
            FilterOption(name: 'Gym', id: 'amen_gym'),
            FilterOption(name: 'Security', id: 'amen_security'),
          ],
        ),
      ],
    );
  }

  /// Example 4: Event Booking Filter
  static FilterExample eventFilterExample() {
    return FilterExample(
      title: 'Events Filter',
      categories: [
        FilterCategory(
          name: 'Category',
          options: [
            FilterOption(name: 'Music', id: 'cat_music'),
            FilterOption(name: 'Sports', id: 'cat_sports'),
            FilterOption(name: 'Theater', id: 'cat_theater'),
            FilterOption(name: 'Comedy', id: 'cat_comedy'),
            FilterOption(name: 'Workshops', id: 'cat_workshops'),
          ],
        ),
        FilterCategory(
          name: 'Date',
          options: [
            FilterOption(name: 'Today', id: 'date_today'),
            FilterOption(name: 'This Week', id: 'date_week'),
            FilterOption(name: 'This Month', id: 'date_month'),
            FilterOption(name: 'This Year', id: 'date_year'),
          ],
        ),
        FilterCategory(
          name: 'Location',
          options: [
            FilterOption(name: 'Downtown', id: 'loc_downtown'),
            FilterOption(name: 'Suburbs', id: 'loc_suburbs'),
            FilterOption(name: 'Online', id: 'loc_online'),
          ],
        ),
      ],
    );
  }
}

/// Helper class to structure filter examples
class FilterExample {
  final String title;
  final List<FilterCategory> categories;

  FilterExample({
    required this.title,
    required this.categories,
  });
}

/// Example widget showing integration with real app state
class FilterIntegrationExample extends StatefulWidget {
  const FilterIntegrationExample({Key? key}) : super(key: key);

  @override
  State<FilterIntegrationExample> createState() =>
      _FilterIntegrationExampleState();
}

class _FilterIntegrationExampleState extends State<FilterIntegrationExample> {
  Map<String, List<String>> activeFilters = {};
  late FilterExample currentFilterExample;
  int selectedExampleIndex = 0;

  final List<FilterExample> examples = [
    AdvancedFilterExamples.gymFilterExample(),
    AdvancedFilterExamples.ecommerceFilterExample(),
    AdvancedFilterExamples.realEstateFilterExample(),
    AdvancedFilterExamples.eventFilterExample(),
  ];

  @override
  void initState() {
    super.initState();
    currentFilterExample = examples[0];
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        title: currentFilterExample.title,
        categories: currentFilterExample.categories,
        initialSelectedFilters: activeFilters,
        onApply: (selectedFilters) {
          setState(() {
            activeFilters = selectedFilters;
          });
          _applyFilters(selectedFilters);
          Navigator.pop(context);
        },
        onClearFilters: () {
          setState(() {
            activeFilters.clear();
          });
          _clearFilters();
        },
      ),
    );
  }

  void _applyFilters(Map<String, List<String>> filters) {
    // Simulate API call with selected filters
    print('Applying filters:');
    filters.forEach((category, options) {
      if (options.isNotEmpty) {
        print('  $category: ${options.join(', ')}');
      }
    });
  }

  void _clearFilters() {
    print('Filters cleared - showing all results');
  }

  String _getFilterSummary() {
    final totalSelected = activeFilters.values
        .fold<int>(0, (sum, list) => sum + list.length);
    if (totalSelected == 0) {
      return 'No filters applied';
    }
    return '$totalSelected filter${totalSelected > 1 ? 's' : ''} applied';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Integration Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Example:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: [
                  for (int i = 0; i < examples.length; i++)
                    ButtonSegment(
                      value: i,
                      label: Text('Example ${i + 1}'),
                    ),
                ],
                selected: {selectedExampleIndex},
                onSelectionChanged: (selection) {
                  setState(() {
                    selectedExampleIndex = selection.first;
                    currentFilterExample = examples[selectedExampleIndex];
                    activeFilters.clear();
                  });
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showFilterBottomSheet,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Open Filters'),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getFilterSummary(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (activeFilters.values.any((list) => list.isNotEmpty))
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            activeFilters.clear();
                          });
                          _clearFilters();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear All'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (activeFilters.values.any((list) => list.isNotEmpty))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Filters:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...activeFilters.entries.map((entry) {
                      if (entry.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (var option in entry.value)
                                  Chip(
                                    label: Text(option),
                                    onDeleted: () {
                                      setState(() {
                                        activeFilters[entry.key]
                                            ?.remove(option);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeFilters.values.any((list) => list.isNotEmpty)
                          ? 'Showing filtered results for ${currentFilterExample.title}'
                          : 'Showing all results',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Total items: ${15 - (activeFilters.values.fold<int>(0, (sum, list) => sum + list.length) * 2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

