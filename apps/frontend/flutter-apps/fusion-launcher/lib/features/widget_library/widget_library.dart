// import 'package:flutter/material.dart';
// import 'package:fusion_launcher/core/service_locator.dart';
// import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
// import 'package:fusion_launcher/features/widget_library/widget_details_section.dart';
// import 'package:fusion_launcher/features/widget_library/widget_list.dart';
// import 'package:fusion_lib/fusion_lib.dart';
//
// class WidgetLibrary extends StatefulWidget {
//   const WidgetLibrary({super.key});
//
//   @override
//   State<WidgetLibrary> createState() => _WidgetLibraryState();
// }
//
// class _WidgetLibraryState extends State<WidgetLibrary> {
//   ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
//
//   @override
//   void dispose() {
//     /// Clear selected snapshot when screen is disposed
//     _projectViewModel.setSelectedEventId(null);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: context.colorScheme.primaryBlack,
//       body: LayoutBuilder(
//         builder: (BuildContext context, BoxConstraints constraints) {
//           final bool isWideScreen = constraints.maxWidth > 600;
//
//           if (isWideScreen) {
//             return Padding(
//               padding: const EdgeInsets.all(4.0),
//               child: Row(
//                 children: <Widget>[
//                   SizedBox(width: constraints.maxWidth * 0.2, child: const WidgetList()),
//                   const SizedBox(width: 4),
//                   const Expanded(child: WidgetDetailsSection()),
//                 ],
//               ),
//             );
//           } else {
//             return const Column(
//               children: <Widget>[
//                 Expanded(flex: 1, child: WidgetList()),
//                 Expanded(flex: 2, child: WidgetDetailsSection()),
//               ],
//             );
//           }
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import 'viewmodel/widget_library_viewmodel.dart';
import 'widget_details_section.dart';
import 'widget_list.dart';

class WidgetLibrary extends StatelessWidget {
  const WidgetLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WidgetLibraryViewModel>(
      create: (BuildContext context) => WidgetLibraryViewModel(),
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: constraints.maxWidth * 0.25,
                      child: const WidgetList(),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(child: WidgetDetailsSection()),
                  ],
                ),
              );
            } else {
              return const Column(
                children: <Widget>[
                  Expanded(flex: 1, child: WidgetList()),
                  Expanded(flex: 2, child: WidgetDetailsSection()),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
