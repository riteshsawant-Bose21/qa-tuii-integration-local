import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_utils/app_enums.dart';

class SortDropdownContent extends StatelessWidget {
  const SortDropdownContent({
    super.key,
    this.selectedSortOption,
    required this.onSortOptionChanged,
  });

  final SortOption? selectedSortOption;
  final ValueChanged<SortOption?> onSortOptionChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 32,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.white,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1)),
            ),
            child: FusionAppText(text: "Sort", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
          ),
          _buildSortOption(
            context: context,
            option: SortOption.priceHighToLow,
            title: 'Price: High to Low',
            image: "assets/images/low_to_high.png",
          ),
          _buildSortOption(
            context: context,
            option: SortOption.priceLowToHigh,
            title: 'Price: Low to High',
            image: "assets/images/high_to_low.png",
          ),
          _buildSortOption(
            context: context,
            option: SortOption.nameAToZ,
            title: 'Product Name: A-Z',
            image: "assets/images/sort_a_to_z.png",
          ),
          _buildSortOption(
            context: context,
            option: SortOption.nameZToA,
            title: 'Product Name: Z-A',
            image: "assets/images/sort_a_to_z.png",
          ),
        ],
      ),
    );
  }

  /// Build individual sort option
  Widget _buildSortOption({required BuildContext context, required SortOption option, required String title, required String image}) {
    final bool isSelected = selectedSortOption == option;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "$title ${option.name}"),
      child: InkWell(
        onTap: () {
          print("Sort option tapped: $option, currently selected: $selectedSortOption");
      
          // Call the callback immediately without any delay
          onSortOptionChanged(option);
      
          // Close popup immediately
          Navigator.of(context).pop();
        },
        child: Container(
          color: isSelected ? Theme.of(context).colorScheme.grey : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              Image.asset(
                image,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FusionAppText(
                  text: title,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
