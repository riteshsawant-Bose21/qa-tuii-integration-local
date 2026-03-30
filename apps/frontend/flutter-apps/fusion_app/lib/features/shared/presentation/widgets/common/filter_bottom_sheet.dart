import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar_search.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/outline_button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/text_field.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<FilterCategory> categories;
  final Function(Map<String, List<String>>) onApply;
  final VoidCallback? onClearFilters;
  final Map<String, List<String>>? initialSelectedFilters;

  final String title;
  final bool focus;

  const FilterBottomSheet({super.key,
    required this.categories,
    required this.onApply,
    required this.focus,
    this.onClearFilters,
    this.initialSelectedFilters,
    this.title = 'FILTERS',
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, List<String>> selectedFilters;
  late List<FilterCategory> categories;
  late String activeCategoryName;
  TextEditingController controller = TextEditingController();
  bool searchEnabled=false;
  FocusNode focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    selectedFilters = widget.initialSelectedFilters ?? {};
    // Initialize empty lists for categories not in initial selection
    for (var category in widget.categories) {
      selectedFilters.putIfAbsent(category.name, () => []);
    }
    categories = widget.categories;
    activeCategoryName = categories.isNotEmpty ? categories[0].name : '';

    focusNode.addListener(() {
      print("Has focus: ${focusNode.hasFocus}");

      if(focusNode.hasFocus){
        if(!searchEnabled){
          searchEnabled = true;
          setState(() {
          });
        }
      }else{
        if(searchEnabled){
          searchEnabled = false;
          setState(() {
          });
        }
      }

    });
      if(widget.focus){
        focusNode.requestFocus();
      }

  }

  void _toggleFilter(String categoryName, String optionName) {
    setState(() {
      if (selectedFilters[categoryName]?.contains(optionName) ?? false) {
        selectedFilters[categoryName]?.remove(optionName);
      } else {
        selectedFilters[categoryName]?.add(optionName);
      }
    });
  }

  void _selectAllInCategory(String categoryName) {
    setState(() {
      final category = categories.firstWhere((c) => c.name == categoryName);

      final allOptions = <String>[];

      for (final filter in category.options) {
        // Add parent option
        allOptions.add(filter.name);

        // Add nested options if present
        if (filter.options != null) {
          allOptions.addAll(filter.options!.map((o) => o.name));
        }
      }
      print("allOptions.length");
      print(categoryName);
      print(selectedFilters[categoryName]);
      print(allOptions.length);

      selectedFilters[categoryName] = allOptions;
    });
  }
  void _deselectAllInCategory(String categoryName) {
    setState(() {
      selectedFilters.remove(categoryName);
    });
  }

  void _clearAllFilters() {
    setState(() {
      for (var category in categories) {
        selectedFilters[category.name]?.clear();
      }
    });
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
  }

  List<FilterOption> _getFilteredOptions(String categoryName) {
    final category = categories.firstWhere((c) => c.name == categoryName);
    if (controller.text.isEmpty) {
      return category.options;
    }
    return category.options
        .where((option) =>
            option.name.toLowerCase().contains(controller.text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: colorScheme.elevation1,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header with title
                SizedBox(height: 24,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.title,
                            style: textTheme.l1Regular.copyWith(
                              color: colorScheme.textBody,
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search field
                      Container(
                          child:AppTextField(
                            controller: controller,
                            focusNode: focusNode,
                            borderColor: colorScheme.elevation3,
                            filledColor: colorScheme.elevation2,
                            hint: 'Search across filters...',
                            onChanges: (String text){
                              setState(() {

                              });
                            },
                            suffixIcon: controller.text.isNotEmpty ? GestureDetector(
                              onTap: (){
                                controller.clear();
                                setState(() {

                                });
                              },
                              child: Icon(
                                  Icons.close,
                                  color: context.colorScheme.iconDefault),
                            ):null,
                            prefixIcon:searchEnabled ? GestureDetector(
                              onTap: (){
                                focusNode.unfocus();
                              },
                              child: Icon(
                                  Icons.chevron_left,
                                  color: context.colorScheme.iconDefault),
                            ): GestureDetector(
                              onTap: (){

                              },
                              child: Icon(
                                  Icons.search,
                                  color: context.colorScheme.iconDefault),
                            ),
                          )),
                    ],
                  ),
                ),
                // Filter content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.elevation2,
                      borderRadius: const BorderRadius.all( Radius.circular(16),
                      ),
                    ),
                    child: buildFilterView(colorScheme, textTheme),
                  ),
                ),
                // Bottom action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildActionButtons(context, colorScheme, textTheme),
                ),
                SizedBox(height: 40,)
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap:() =>  Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:context.colorScheme.elevation1,
              shape: BoxShape.circle,
              boxShadow:  [
                BoxShadow(
                  color: context.colorScheme.elevation1,
                  blurRadius: 12,
                ),
              ],
            ),
            child:  Icon(Icons.close, color:  context.colorScheme.onPrimary),
          ),
        )
      ],
    );
  }

  Widget emptySearchView(){
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 64,),
          Text(
            'Start searching for filters',
            style: context.textTheme.h5BoldMobile.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: context.colorScheme.textPrimary,
            )
            ),
          SizedBox(height: 8,),
          Text(
              'Type and find the filter you need',
              style: context.textTheme.b3Regular.copyWith(
                color: context.colorScheme.textBody,
              )
          ),
        ],
      ),
    );
  }

  Widget buildFilterView(ColorScheme colorScheme, TextTheme textTheme) {

    if(searchEnabled && controller.text.isEmpty){
      return emptySearchView();
    }else if(searchEnabled && controller.text.isNotEmpty){
      return _buildFilterOptions(colorScheme, textTheme);
    }


    return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left sidebar - Category labels
                _buildCategorySidebar(colorScheme, textTheme),
                // Right side - Filter options
                Expanded(
                  child: _buildFilterOptions(colorScheme, textTheme),
                ),
              ],
            );
  }


  Widget _buildCategorySidebar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < categories.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < categories.length - 1 ? 20 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    activeCategoryName = categories[i].name;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            categories[i].name,
                            style: textTheme.b3SemiBold.copyWith(
                              color: activeCategoryName == categories[i].name
                                  ? colorScheme.primaryWhite
                                  : colorScheme.textBody,
                            ),
                          ),
                        ),
                        if (activeCategoryName == categories[i].name)
                          Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryWhite,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Only show options for active category
              if (activeCategoryName.isNotEmpty)
                ..._buildActiveCategoryOptions(
                  colorScheme,
                  textTheme,
                  activeCategoryName,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveCategoryOptions(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String categoryName,
  ) {
    final categoryIndex =
        categories.indexWhere((c) => c.name == categoryName);
    if (categoryIndex == -1) return [];

    return [
      // Select All option
      _buildFilterTile(
        colorScheme,
        textTheme,
        categoryName,
        'Select All',
        isSelectAll: true,
        isSelected: isAllSelected(categoryName,categoryIndex),
        onChanged: (isSelected) {
          if (isSelected ?? false) {
            _selectAllInCategory(categoryName);
          } else {
            _deselectAllInCategory(categoryName);
          }
        },
      ),
      const SizedBox(height: 16),
      // Individual filter options
      for (var option in _getFilteredOptions(categoryName))
        Column(
          children: [
            _buildFilterTile(
              colorScheme,
              textTheme,
              categoryName,
              option.name,
              isSelected: selectedFilters[categoryName]?.contains(option.name),
              onChanged: (isSelected) {
                _toggleFilter(categoryName, option.name);
              },
            ),
            (option.options?.isNotEmpty ?? false) ? SizedBox(height: 20) : SizedBox.shrink(),
            ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: NeverScrollableScrollPhysics(),
                itemCount: option.options?.length ?? 0,
                separatorBuilder: (context,i){
                    return  SizedBox(height: 20,);
                },
                itemBuilder: (context,i){
                  Option item = option.options![i];
                  return _buildFilterTile(
                    colorScheme,
                    textTheme,
                    categoryName,
                    item.name,
                    isSelected: selectedFilters[categoryName]?.contains(item.name),
                    onChanged: (isSelected) {
                      _toggleFilter(categoryName, item.name);
                    },
                  );
                }),
            SizedBox(height: 20),
            if(option.options!=null )
            ...[
              CommonDivider(paddingValue: 0,),
              SizedBox(height: 20),
            ],

          ],
        )
    ];
  }

  Widget _buildFilterTile(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String categoryName,
    String optionName, {
    bool? isSelected,
    bool isSelectAll = false,
    required Function(bool?) onChanged,
  }) {
    final isOptionSelected = isSelected ?? false;

    return GestureDetector(
      onTap: () => onChanged(!isOptionSelected),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              optionName,
              style: isSelectAll
                  ? textTheme.b3SemiBold.copyWith(
                      color: isOptionSelected
                          ? colorScheme.primaryWhite
                          : colorScheme.textPrimary,
                    )
                  : textTheme.b3Regular.copyWith(
                      color: isOptionSelected
                          ? colorScheme.primaryWhite
                          : colorScheme.textBody,
                    ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isOptionSelected ? colorScheme.iconWhite : Colors.transparent,
              border: Border.all(
                color: isOptionSelected
                    ? colorScheme.iconWhite
                    : colorScheme.textDisabled,

              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isOptionSelected
                ? Center(
                    child: Icon(Icons.done, size: 12, color: context.colorScheme.primaryBlack),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: CustomOutlineButton(
            enabled: ValueNotifier(controller.text.isNotEmpty ? true:false),
            backGroundColor:  colorScheme.elevation1,
            buttonText: 'Clear Filters',
            onPressed: _clearAllFilters,
          ),

        ),
        const SizedBox(width: 12),
        Expanded(
          child:
          CustomButton(
            enabled: ValueNotifier(controller.text.isNotEmpty ? true:false),
            buttonText: 'Apply',
            bottomPadding: 0,
            padding: EdgeInsetsGeometry.zero,
            onPressed: () {
                  widget.onApply(selectedFilters);
                  Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

    bool isAllSelected(String categoryName, int categoryIndex) {
      final category = categories[categoryIndex];

      final totalOptions = category.options.fold<int>(0, (sum, filter) {
        if (filter.options != null && filter.options!.isNotEmpty) {
          return sum + filter.options!.length; // count children
        }
        return sum + 1; // count parent if no children
      });

      final selectedCount = selectedFilters[categoryName]?.length ?? 0;
      print("isAllSelected: " +category.name);
      print(selectedCount);
      print(totalOptions);
      return selectedCount == totalOptions;
    }
}

/// Model class representing a filter category
class FilterCategory {
  final String name;
  final List<FilterOption> options;

  FilterCategory({
    required this.name,
    required this.options,
  });
}

/// Model class representing a single filter option
class FilterOption {
  final List<Option>? options;
  final String? id;
  final String name;

  FilterOption({
    required this.name,
     this.options,
    this.id,
  });
}

class Option {
  final String name;
  final String? id;

  Option({
    required this.name,
    this.id,
  });
}

