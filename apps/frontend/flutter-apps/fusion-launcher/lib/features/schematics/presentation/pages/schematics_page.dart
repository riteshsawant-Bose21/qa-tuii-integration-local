import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/schematics/presentation/pages/schematics_listing_view.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_page.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class SchematicsPage extends StatefulWidget {
  const SchematicsPage({super.key});

  @override
  State<SchematicsPage> createState() => _SchematicsPageState();
}

class _SchematicsPageState extends State<SchematicsPage> {
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();
  bool get isListingViewMode => _projectViewModel.currentProjectMode == ProjectMode.systemListingMode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, Object? state) {
        return FusionKeyboardWrapper(
          onUndo: () {
            // if (serviceLocator<ProjectViewModel>().canUndo) {
            //   serviceLocator<ProjectViewModel>().undo();
            // }
          },
          onRedo: () {
            // if (serviceLocator<ProjectViewModel>().canRedo) {
            //   serviceLocator<ProjectViewModel>().redo();
            // }
          },
          onDelete: () {
            //delete selected item with a confirmation dialog
            //show dialog
            final SelectedItem? selectedItem = _projectViewModel.selectedDevice;
            if (selectedItem != null) {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Delete Items"),
                    content: FusionAppText(
                      semanticId: "dialog_delete_selected_item_confirmation",
                      text: "Are you sure you want to delete the selected ${selectedItem.type.name}?",
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _projectViewModel.deleteSelectedItem();
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: isListingViewMode ? const SchematicsListingview() : const WiringPage(),
        );
      },
    );
  }
}
