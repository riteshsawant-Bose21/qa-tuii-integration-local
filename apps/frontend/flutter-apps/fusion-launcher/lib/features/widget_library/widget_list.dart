// import 'package:flutter/material.dart';
// import 'package:fusion_lib/fusion_lib.dart';
//
// import '../configuration_page/widgets/section_header.dart';
//
// class WidgetList extends StatelessWidget {
//   const WidgetList({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: <Widget>[
//         const SectionHeader(
//           title: 'Widgets Library',
//         ),
//
//         /// Event list
//         Expanded(
//           child: Container(
//             clipBehavior: Clip.hardEdge,
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(12),
//                 bottomRight: Radius.circular(12),
//               ),
//               border: Border(
//                 bottom: BorderSide(
//                   color: context.colorScheme.elevation2,
//                   width: 1,
//                 ),
//                 left: BorderSide(
//                   color: context.colorScheme.elevation2,
//                   width: 1,
//                 ),
//                 right: BorderSide(
//                   color: context.colorScheme.elevation2,
//                   width: 1,
//                 ),
//               ),
//               color: Theme.of(context).colorScheme.elevation1,
//             ),
//             child: const Center(
//               child: FusionAppText(text: 'Widget List'),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import 'models/widget_category.dart';
import 'models/widget_item.dart';
import 'viewmodel/widget_library_viewmodel.dart';

class WidgetList extends StatelessWidget {
  const WidgetList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WidgetLibraryViewModel>(
      builder: (
        BuildContext context,
        WidgetLibraryViewModel viewModel,
        Widget? child,
      ) {
        return Column(
          children: <Widget>[
            const FusionAppText(
              text: 'Widgets Library',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            /// Widget categories list
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: context.colorScheme.elevation2,
                      width: 1,
                    ),
                    left: BorderSide(
                      color: context.colorScheme.elevation2,
                      width: 1,
                    ),
                    right: BorderSide(
                      color: context.colorScheme.elevation2,
                      width: 1,
                    ),
                  ),
                  color: Theme.of(context).colorScheme.elevation1,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children:
                      WidgetCategory.values
                          .map(
                            (WidgetCategory category) => _buildCategorySection(
                              context,
                              viewModel,
                              category,
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
    WidgetCategory category,
  ) {
    final List<WidgetItem> widgets = viewModel.getWidgetsByCategory(category);
    final bool isExpanded = viewModel.isCategoryExpanded(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.colorScheme.elevation2,
            width: 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            // Category Header
            InkWell(
              onTap: () => viewModel.toggleCategory(category),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 5),
                    Expanded(
                      child: FusionAppText(
                        text: category.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FusionAppText(
                        text: '${widgets.length}',
                        style: TextStyle(
                          color: context.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),

            // Widgets list
            if (isExpanded && widgets.isNotEmpty) ...<Widget>[
              const Divider(height: 1),
              ...widgets.map(
                (WidgetItem w) => _buildWidgetItem(context, viewModel, w),
              ),
            ],

            // Empty message
            if (isExpanded && widgets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: FusionAppText(
                  text: 'No widgets yet',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetItem(
    BuildContext context,
    WidgetLibraryViewModel viewModel,
    WidgetItem widget,
  ) {
    final bool isSelected = viewModel.selectedWidget == widget;

    return InkWell(
      onTap: () => viewModel.setSelectedWidget(widget),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? context.colorScheme.primary.withOpacity(0.15)
                  : Colors.transparent,
          border: Border(
            left: BorderSide(
              color:
                  isSelected ? context.colorScheme.primary : Colors.transparent,
              width: 10,
            ),
          ),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: widget.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? context.colorScheme.primary
                              : context.colorScheme.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
