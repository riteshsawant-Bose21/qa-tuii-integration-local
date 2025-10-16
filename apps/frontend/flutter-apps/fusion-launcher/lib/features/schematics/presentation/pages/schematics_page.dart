import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/wiring_design/view/wiring_page.dart';
import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'schematics_main_panel.dart';

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
        return Column(
          children: <Widget>[
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                border: Border(
                  bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
                ),
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      _projectViewModel.setProjectMode(ProjectMode.systemListingMode);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      color: isListingViewMode ? Colors.black87 : Colors.transparent,
                      child: SvgPicture.asset(
                        "assets/svg/listing_view_icon.svg",
                        width: 40,
                        height: 40,
                        colorFilter: ColorFilter.mode(
                          isListingViewMode ? Colors.white : Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _projectViewModel.setProjectMode(ProjectMode.systemWiringMode);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      color: !isListingViewMode ? Colors.black87 : Colors.transparent,
                      child: SvgPicture.asset(
                        "assets/svg/wiring_view_icon.svg",
                        width: 40,
                        height: 40,
                        colorFilter: ColorFilter.mode(
                          !isListingViewMode ? Colors.white : Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Main Panel
            Expanded(
              child: isListingViewMode ? const SchematicsMainPanel() : const WiringPage(),
            ),
          ],
        );
      },
    );
  }
}
