// import 'package:flutter/material.dart';
// import 'package:fusion_app/features/shared/presentation/widgets/common/filter_bottom_sheet.dart';
//
// /// Quick Integration Guide - Copy & Paste Examples
// ///
// /// This file provides ready-to-use code snippets for common scenarios
//
// /// EXAMPLE 1: Simple integration in a page
// /// Copy this into any screen/page widget
// class FilterPageExample extends StatefulWidget {
//   const FilterPageExample({Key? key}) : super(key: key);
//
//   @override
//   State<FilterPageExample> createState() => _FilterPageExampleState();
// }
//
// class _FilterPageExampleState extends State<FilterPageExample> {
//   Map<String, List<String>> selectedFilters = {};
//
//   void _openFilter() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => FilterBottomSheet(
//         title: 'FILTERS',
//         categories: [
//           FilterCategory(
//             name: 'Zones',
//             options: [
//               FilterOption(name: 'Zone 1', id: 'zone_1'),
//               FilterOption(name: 'Zone 2', id: 'zone_2'),
//               FilterOption(name: 'Zone 3', id: 'zone_3'),
//             ],
//           ),
//           FilterCategory(
//             name: 'Type',
//             options: [
//               FilterOption(name: 'Reception', id: 'reception'),
//               FilterOption(name: 'Fitness', id: 'fitness'),
//               FilterOption(name: 'Cardio', id: 'cardio'),
//             ],
//           ),
//         ],
//         initialSelectedFilters: selectedFilters,
//         onApply: (filters) {
//           setState(() {
//             selectedFilters = filters;
//           });
//           _fetchData(filters);
//         },
//         onClearFilters: () {
//           setState(() {
//             selectedFilters.clear();
//           });
//           _fetchData({});
//         },
//       ),
//     );
//   }
//
//   Future<void> _fetchData(Map<String, List<String>> filters) async {
//     // TODO: Call your API with selected filters
//     print('Fetching data with filters: $filters');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Filtered List'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             onPressed: _openFilter,
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Your filtered content here'),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _openFilter,
//               child: const Text('Open Filter'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// EXAMPLE 2: Integration with API call and loading state
// class FilterWithAPIExample extends StatefulWidget {
//   const FilterWithAPIExample({Key? key}) : super(key: key);
//
//   @override
//   State<FilterWithAPIExample> createState() => _FilterWithAPIExampleState();
// }
//
// class _FilterWithAPIExampleState extends State<FilterWithAPIExample> {
//   Map<String, List<String>> selectedFilters = {};
//   List<String> results = [];
//   bool isLoading = false;
//   String? error;
//
//   void _openFilter() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => FilterBottomSheet(
//         title: 'FILTERS',
//         categories: _buildFilterCategories(),
//         initialSelectedFilters: selectedFilters,
//         onApply: (filters) {
//           Navigator.pop(context);
//           _applyFilters(filters);
//         },
//         onClearFilters: () {
//           Navigator.pop(context);
//           _clearFilters();
//         },
//       ),
//     );
//   }
//
//   List<FilterCategory> _buildFilterCategories() {
//     return [
//       FilterCategory(
//         name: 'Category',
//         options: [
//           FilterOption(name: 'All', id: 'all'),
//           FilterOption(name: 'Active', id: 'active'),
//           FilterOption(name: 'Inactive', id: 'inactive'),
//         ],
//       ),
//       FilterCategory(
//         name: 'Status',
//         options: [
//           FilterOption(name: 'Available', id: 'available'),
//           FilterOption(name: 'Unavailable', id: 'unavailable'),
//         ],
//       ),
//     ];
//   }
//
//   Future<void> _applyFilters(Map<String, List<String>> filters) async {
//     setState(() {
//       selectedFilters = filters;
//       isLoading = true;
//       error = null;
//     });
//
//     try {
//       // Simulate API call - Replace with actual API call
//       await Future.delayed(const Duration(seconds: 1));
//
//       setState(() {
//         results = ['Result 1', 'Result 2', 'Result 3'];
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         error = e.toString();
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _clearFilters() async {
//     setState(() {
//       selectedFilters.clear();
//       isLoading = true;
//       error = null;
//     });
//
//     try {
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         results = [];
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         error = e.toString();
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Filtered Results'),
//         actions: [
//           Stack(
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.filter_list),
//                 onPressed: _openFilter,
//               ),
//               if (selectedFilters.values.any((list) => list.isNotEmpty))
//                 Positioned(
//                   right: 8,
//                   top: 8,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       selectedFilters.values
//                           .fold<int>(0, (sum, list) => sum + list.length)
//                           .toString(),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : error != null
//               ? Center(child: Text('Error: $error'))
//               : results.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text('No results found'),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: _openFilter,
//                             child: const Text('Adjust Filters'),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: results.length,
//                       itemBuilder: (context, index) => ListTile(
//                         title: Text(results[index]),
//                       ),
//                     ),
//     );
//   }
// }
//
// /// EXAMPLE 3: Integration with Provider state management
// /// (Requires: flutter pub add provider)
// ///
// /// First, create a FilterProvider:
// ///
// /// class FilterProvider extends ChangeNotifier {
// ///   Map<String, List<String>> _selectedFilters = {};
// ///   List<dynamic> _results = [];
// ///   bool _isLoading = false;
// ///
// ///   Map<String, List<String>> get selectedFilters => _selectedFilters;
// ///   List<dynamic> get results => _results;
// ///   bool get isLoading => _isLoading;
// ///
// ///   void setFilters(Map<String, List<String>> filters) {
// ///     _selectedFilters = filters;
// ///     notifyListeners();
// ///     _fetchResults();
// ///   }
// ///
// ///   void clearFilters() {
// ///     _selectedFilters.clear();
// ///     notifyListeners();
// ///     _fetchResults();
// ///   }
// ///
// ///   Future<void> _fetchResults() async {
// ///     _isLoading = true;
// ///     notifyListeners();
// ///
// ///     try {
// ///       // API call with _selectedFilters
// ///       await Future.delayed(const Duration(seconds: 1));
// ///       _results = ['Item 1', 'Item 2'];
// ///     } finally {
// ///       _isLoading = false;
// ///       notifyListeners();
// ///     }
// ///   }
// /// }
// ///
// /// Then use it like this in your widget:
//
// class FilterWithProviderExample extends StatelessWidget {
//   const FilterWithProviderExample({Key? key}) : super(key: key);
//
//   void _openFilter(BuildContext context) {
//     // final filterProvider = context.read<FilterProvider>();
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => FilterBottomSheet(
//         title: 'FILTERS',
//         categories: [
//           FilterCategory(
//             name: 'Type',
//             options: [
//               FilterOption(name: 'Option 1', id: 'opt1'),
//               FilterOption(name: 'Option 2', id: 'opt2'),
//             ],
//           ),
//         ],
//         // initialSelectedFilters: filterProvider.selectedFilters,
//         onApply: (filters) {
//           // context.read<FilterProvider>().setFilters(filters);
//           Navigator.pop(context);
//         },
//         onClearFilters: () {
//           // context.read<FilterProvider>().clearFilters();
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Provider Example'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.filter_list),
//             onPressed: () => _openFilter(context),
//           ),
//         ],
//       ),
//       body: const Center(
//         child: Text('Check comments in code for Provider setup'),
//       ),
//     );
//   }
// }
//
// /// EXAMPLE 4: Dynamic filter categories from API
// class DynamicFilterExample extends StatefulWidget {
//   const DynamicFilterExample({Key? key}) : super(key: key);
//
//   @override
//   State<DynamicFilterExample> createState() => _DynamicFilterExampleState();
// }
//
// class _DynamicFilterExampleState extends State<DynamicFilterExample> {
//   Map<String, List<String>> selectedFilters = {};
//   late Future<List<FilterCategory>> filterCategoriesFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     filterCategoriesFuture = _fetchFilterCategories();
//   }
//
//   Future<List<FilterCategory>> _fetchFilterCategories() async {
//     // Simulate API call to fetch filter categories
//     await Future.delayed(const Duration(seconds: 1));
//
//     return [
//       FilterCategory(
//         name: 'Category A',
//         options: [
//           FilterOption(name: 'Option 1', id: 'opt1'),
//           FilterOption(name: 'Option 2', id: 'opt2'),
//         ],
//       ),
//       FilterCategory(
//         name: 'Category B',
//         options: [
//           FilterOption(name: 'Option 3', id: 'opt3'),
//           FilterOption(name: 'Option 4', id: 'opt4'),
//         ],
//       ),
//     ];
//   }
//
//   void _openFilter(List<FilterCategory> categories) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => FilterBottomSheet(
//         title: 'FILTERS',
//         categories: categories,
//         initialSelectedFilters: selectedFilters,
//         onApply: (filters) {
//           setState(() {
//             selectedFilters = filters;
//           });
//           Navigator.pop(context);
//         },
//         onClearFilters: () {
//           setState(() {
//             selectedFilters.clear();
//           });
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dynamic Filters'),
//       ),
//       body: FutureBuilder<List<FilterCategory>>(
//         future: filterCategoriesFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           final categories = snapshot.data ?? [];
//
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text('Filters loaded from API'),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => _openFilter(categories),
//                   child: const Text('Open Dynamic Filters'),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// /// EXAMPLE 5: Minimal setup - Absolute minimum code needed
// class MinimalFilterExample extends StatefulWidget {
//   const MinimalFilterExample({Key? key}) : super(key: key);
//
//   @override
//   State<MinimalFilterExample> createState() => _MinimalFilterExampleState();
// }
//
// class _MinimalFilterExampleState extends State<MinimalFilterExample> {
//   void _showFilter() => showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => FilterBottomSheet(
//       categories: [
//         FilterCategory(
//           name: 'Type',
//           options: [
//             FilterOption(name: 'A'),
//             FilterOption(name: 'B'),
//           ],
//         ),
//       ],
//       onApply: (filters) => print(filters),
//     ),
//   );
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     appBar: AppBar(title: const Text('Filter')),
//     body: Center(
//       child: ElevatedButton(
//         onPressed: _showFilter,
//         child: const Text('Filter'),
//       ),
//     ),
//   );
// }
//
//
