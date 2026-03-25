import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';

class SearchBarSources extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback? onClearSearch;
  final bool Function() hasActiveFilters;
  final Widget? activeFiltersChipsRow;
  final ValueChanged<String>? onSearchChanged;
  final bool isFromActionList;

  const SearchBarSources({
    super.key,
    required this.searchController,
    required this.hasActiveFilters,
    this.activeFiltersChipsRow,
    this.onClearSearch,
    this.onSearchChanged,
    this.isFromActionList = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          border:
              isFromActionList
                  ? null
                  : Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// Search + filter + sort row
            Container(
              color: context.colorScheme.elevation2,
              height: 32,
              child: Row(
                children: <Widget>[
                  /// Search box
                  Expanded(
                    child: SemanticHelper.formControl(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.textInput,
                        "search_bar_sources",
                      ),
                      child: FusionTextField(
                        semanticFieldId: 'search_bar_sources',
                        controller: searchController,
                        hintText: 'Search sources',

                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                        onChanged: (String value) {
                          if (value.isEmpty) {
                            onClearSearch?.call();
                          }
                          onSearchChanged?.call(value);
                        },
                        suffixIcon:
                            searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[400],
                                    size: 16,
                                  ),
                                  onPressed: onClearSearch,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                                : null,
                      ),
                    ),
                  ),

                  // /// Filter Dropdown
                  // _buildDropdownButton(
                  //   context: context,
                  //   image: "assets/images/filter.png",
                  //   tooltip: 'Filter',
                  //   hasActiveFilters: false,
                  //   dropdownBuilder: (BuildContext context) => const SizedBox(),
                  // ),
                  // const SizedBox(width: 8),
                  //
                  // /// Sort Dropdown
                  // _buildDropdownButton(
                  //   context: context,
                  //   image: "assets/images/sort_descending.png",
                  //   tooltip: 'Sort',
                  //   hasActiveFilters: false, // Show active state when sort is selected
                  //   dropdownBuilder:
                  //       (BuildContext context) => SortDropdownContent(
                  //         selectedSortOption: selectedSortOption,
                  //         onSortOptionChanged: onSortOptionChanged ?? (SortOption? option) {},
                  //       ),
                  // ),
                  // const SizedBox(width: 8),
                ],
              ),
            ),

            // /// Active filters chips row
            // if (hasActiveFilters()) activeFiltersChipsRow ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  /// Build dropdown button with custom dropdown content
  Widget _buildDropdownButton({
    required BuildContext context,
    required String image,
    required String tooltip,
    required bool hasActiveFilters,
    required Widget Function(BuildContext) dropdownBuilder,
  }) {
    return PopupMenuButton<void>(
      tooltip: tooltip,
      color: context.colorScheme.elevation1,
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<void>>[
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: dropdownBuilder(context),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration:
            hasActiveFilters
                ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                )
                : null,
        child: Image.asset(
          image,
          height: 16,
          width: 16,
        ),
      ),
    );
  }
}
