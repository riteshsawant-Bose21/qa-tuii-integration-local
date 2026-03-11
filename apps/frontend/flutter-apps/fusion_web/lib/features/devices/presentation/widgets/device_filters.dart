import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/presentation/widgets/filter_dropdown.dart';
import 'package:fusion_web/features/devices/presentation/widgets/view_toggle_button.dart';

class DeviceFilters extends StatelessWidget {
  final TextEditingController searchController;

  final String selectedStatus;
  final String selectedProjects;
  final String selectedModels;
  final String selectedTypes;
  final String selectedCategory;

  final bool isGridView;
  final bool showClearFilters;
  final VoidCallback onClearFilters;

  final List<String> statusItems;
  final List<String> projectItems;
  final List<String> modelItems;
  final List<String> typeItems;
  final List<String> categoryItems;

  final Function(String?) onStatusChanged;
  final Function(String?) onProjectChanged;
  final Function(String?) onModelChanged;
  final Function(String?) onTypeChanged;
  final Function(String?) onCategoryChanged;
  final Function(String)? onSearchChanged;

  final VoidCallback onGridTap;
  final VoidCallback onListTap;

  const DeviceFilters({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.selectedProjects,
    required this.selectedModels,
    required this.selectedTypes,
    required this.selectedCategory,
    required this.isGridView,
    required this.showClearFilters,
    required this.onClearFilters,
    required this.statusItems,
    required this.projectItems,
    required this.modelItems,
    required this.typeItems,
    required this.categoryItems,
    required this.onStatusChanged,
    required this.onProjectChanged,
    required this.onModelChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onGridTap,
    required this.onListTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        /// ROW 1
        Row(
          children: [

            /// SEARCH
            SizedBox(
              width: 320,
              child: TextFormField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: _inputDecoration(
                  'Search devices...',
                  Icons.search,
                ),
              ),
            ),

            const SizedBox(width: 16),

            /// STATUS
            SizedBox(
              width: 180,
              child: FilterDropdown(
                value: selectedStatus,
                items: statusItems,
                onChanged: onStatusChanged,
              ),
            ),

            const SizedBox(width: 16),

            /// PROJECT
            SizedBox(
              width: 180,
              child: FilterDropdown(
                value: selectedProjects,
                items: projectItems,
                onChanged: onProjectChanged,
              ),
            ),

            const SizedBox(width: 16),

            /// MODEL
            SizedBox(
              width: 180,
              child: FilterDropdown(
                value: selectedModels,
                items: modelItems,
                onChanged: onModelChanged,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// ROW 2
        Row(
          children: [

            /// TYPE
            SizedBox(
              width: 180,
              child: FilterDropdown(
                value: selectedTypes,
                items: typeItems,
                onChanged: onTypeChanged,
              ),
            ),

            const SizedBox(width: 16),

            /// CATEGORY
            SizedBox(
              width: 180,
              child: FilterDropdown(
                value: selectedCategory,
                items: categoryItems,
                onChanged: onCategoryChanged,
              ),
            ),

            const SizedBox(width: 16),

            /// CLEAR FILTERS
            if (showClearFilters)
              _ClearFilterButton(onTap: onClearFilters),

            /// PUSH GRID BUTTONS RIGHT
            const Spacer(),

            /// VIEW TOGGLE
            _viewToggle(),
          ],
        ),
      ],
    );
  }

  Widget _viewToggle() {
    return Row(
      children: [
        ViewToggleButton(
          icon: Icons.view_list_rounded,
          isSelected: !isGridView,
          onTap: onListTap,
        ),
        const SizedBox(width: 8),
        ViewToggleButton(
          icon: Icons.grid_view_rounded,
          isSelected: isGridView,
          onTap: onGridTap,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _ClearFilterButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ClearFilterButton({required this.onTap});

  @override
  State<_ClearFilterButton> createState() => _ClearFilterButtonState();
}

class _ClearFilterButtonState extends State<_ClearFilterButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: isHovering ? Colors.grey[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),

              // IMPORTANT: keep border width constant
              border: Border.all(
                color: isHovering
                    ? Colors.grey.shade400
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: const Text(
              "Clear Filters",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black, // always black
              ),
            ),
          ),
        ),
      ),
    );
  }
}