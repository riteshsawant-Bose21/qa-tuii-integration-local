import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/bug_report_popup.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/core/widgets/clean_widgets.dart';
import 'package:fusion_launcher/features/create_new_project/views/create_new_project_dialog.dart';
import 'package:fusion_launcher/features/projects/constant/semantic_keys.dart';
import 'package:fusion_launcher/features/projects/view_model/project_sync_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/fusion_theme_notifier.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/assets/asset_icons.dart';
import '../../../../authentication/viewmodel/session_view_model.dart';
import '../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../devices/presentation/widgets/device_mapping_dialog.dart';
import '../../../view_model/dsp_sync/config_sync_view_model.dart';
import '../../../widget/control_design_tab_switcher.dart';

part '_app_bar_content.dart';
part '_project_name_section.dart';
part '_work_area_appbar_action.dart';

class ProjectWorkAreaAppBar extends StatelessWidget {
  const ProjectWorkAreaAppBar({super.key, required this.tabController, required this.currentTabs});
  final TabController tabController;
  final List<Widget> currentTabs;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const _ProjectNameSection(),
        Expanded(
          child: _AppBarContent(
            tabController: tabController,
            currentTabs: currentTabs,
          ),
        ),
      ],
    );
  }
}

// Usage example in your code:
Future<void> handleExportLogs(BuildContext context) async {
  final String? choice = await showShareDownloadPopup(context);

  if (choice == null) return; // User cancelled

  if (choice == 'feedback') {
    // Show feedback webview
    await showFeedbackWebView(context);
    return;
  }

  FusionUiUtils.showLoader(context);

  try {
    final List<XFile> logsList = await FusionUtils.generateSharableLogsFiles();
    File? projectFile;

    // Get project file for download option
    projectFile = await serviceLocator<ProjectViewModel>().getCurrentProjectFile();
    if (projectFile != null) {
      logsList.add(FusionUtils.generateXFile(projectFile));
    }

    if (context.mounted) FusionUiUtils.hideLoader(context);

    if (choice == 'share') {
      // Share logs only (Notes will be available on macOS)
      await SharePlus.instance.share(
        ShareParams(
          text: "Fusion Logs ${DateTime.now()}",
          files: logsList,
        ),
      );
    } else if (choice == 'download') {
      // Download locally - choose your preferred method:

      // Option 1: Download as separate files in a folder
      if (context.mounted) await downloadFilesLocally(context, logsList, projectFile: projectFile);

      // Option 2: Download as a single ZIP file
      // await downloadAsZip(context, logsList, projectFile: projectFile);
    }
  } catch (e, st) {
    if (context.mounted) FusionUiUtils.hideLoader(context);
    FusionLogger.log(
      tag: LogTag.exceptions,
      message: "Export failed: $e\n$st",
    );
  }
}
