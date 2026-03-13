import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionMultiFilterChips<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) labelBuilder;
  final Set<T>? initialSelected;
  final Function? onChanged;

  const FusionMultiFilterChips({
    super.key,
    required this.items,
    required this.labelBuilder,
    this.initialSelected,
    this.onChanged,
  });

  @override
  State<FusionMultiFilterChips> createState() => _FusionMultiFilterChipsState();
}

class _FusionMultiFilterChipsState<T> extends State<FusionMultiFilterChips<T>> {

  late Set<T> selectedItems;
  @override
  void initState() {
    super.initState();
    selectedItems = widget.initialSelected ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = selectedItems.contains(item);

          return GestureDetector(
            onTap: index != 0 ? () {
              setState(() {
                if (isSelected) {
                  selectedItems.remove(item);
                } else {
                  selectedItems.add(item);
                }
              });

              widget.onChanged!(selectedItems);
            }:null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colorScheme.elevation2
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ?Colors.transparent
                      :  context.colorScheme.elevation3,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  if (index == 0) ...[
                    if(selectedItems.isNotEmpty)...[
                    Container(
                      alignment: Alignment.center,
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color:context.colorScheme.elevation4,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: context.colorScheme.elevation2,
                        ),
                      ),
                      child: Text(
                        selectedItems.length.toString(),
                        style: Theme.of(context).textTheme.l2Bold.copyWith(
                          fontWeight: FontWeight.w700,
                          color:context.colorScheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ],
                    Icon(
                      Icons.tune,
                      size: 18,
                      color:context.colorScheme.iconDefault,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    item.toString(),
                    style: Theme.of(context).textTheme.l1Regular.copyWith(
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? context.colorScheme.textPrimary
                          : context.colorScheme.textSecondary,
                    ),
                  ),
                  if(isSelected && index != 0)...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.close,
                      size: 15,
                      color:context.colorScheme.iconWhite,
                    ),
                  ]

                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: widget.items.length,
      ),
    );
  }
}