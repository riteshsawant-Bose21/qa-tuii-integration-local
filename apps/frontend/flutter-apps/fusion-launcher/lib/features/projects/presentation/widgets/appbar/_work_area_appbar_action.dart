part of 'project_work_area_appbar.dart';

class _WorkAreaAppbarAction extends StatelessWidget {
  const _WorkAreaAppbarAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isInDesignMode = !serviceLocator<ProjectViewModel>().isInControlMode;
        return Row(
          children: <Widget>[
            if (!isInDesignMode && serviceLocator<ProjectViewModel>().virtualIP != null)
              Container(
                width: 160,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                ),

                alignment: Alignment.center,
                child: SizedBox(
                  height: 35,
                  child: BlocListener<ConfigSyncViewModel, ConfigSyncState>(
                    listener: (BuildContext context, ConfigSyncState state) {
                      if (state is ProcessingDataWithDro || state is SyncingConfigWithDsp) {
                        FusionUiUtils.showLoader(context);
                      } else {
                        FusionUiUtils.hideLoader(context);

                        if (state is DroProcessingFailed) {
                          FusionToast.error(
                            context,
                            message: state.message,
                          );
                        } else if (state is ConfigSyncFailure) {
                          FusionToast.error(
                            context,
                            message: state.message,
                          );
                        } else if (state is ConfigSyncedWithDsp) {
                          FusionToast.success(
                            context,
                            message: "Configuration synced successfully",
                          );
                        }
                      }
                    },
                    child: FusionNeumorphicButton(
                      semanticId: "push_configuration",
                      onTap: () {
                        serviceLocator<ConfigSyncViewModel>().refineAndSyncDataWithDsp(
                          droInput: serviceLocator<ProjectViewModel>().getDroInputData(),
                        );
                      },
                      height: 20,
                      borderRadius: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      text: "Push Configuration",
                      textStyle: context.textTheme.labelMedium,
                    ),
                  ),
                ),
              ),

            if (!isInDesignMode && serviceLocator<ProjectViewModel>().virtualIP != null)
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, "device_mapping_icon"),
                child: Container(
                  width: 56,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation1,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation3,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: InkWell(
                      onTap: () {
                        DeviceMappingDialog.show(context);
                      },
                      child: FusionImage.asset(
                        AssetIcons.networkIcon,
                        assetColor: Theme.of(context).colorScheme.iconWhite,
                      ),
                    ),
                  ),
                ),
              ),

            if (kDebugMode)
              /// Theme Change Icon Section (Debug Only)
              Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(width: 1, color: context.colorScheme.elevation2),
                  ),
                ),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: FusionThemeController.themeModeNotifier,
                  builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
                    return IconButton(
                      icon: Icon(
                        themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                        size: 24,
                        color: Theme.of(context).colorScheme.primaryWhite,
                      ),
                      tooltip: themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                      onPressed: () {
                        final bool isLight = FusionThemeController.themeModeNotifier.value == ThemeMode.light;
                        FusionThemeController.setThemeMode(
                          isLight ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    );
                  },
                ),
              ),

            /// Save Icon Section
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.saveProject),
              child: Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(width: 1, color: context.colorScheme.elevation2),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.save,
                    size: 24,
                    color: Theme.of(context).colorScheme.primaryWhite,
                  ),
                  tooltip: 'Save project',
                  onPressed: () => _showProjectJsonDialog(context),
                  onLongPress: () => serviceLocator<ProjectViewModel>().deleteCurrentProjectFromLocal(),
                ),
              ),
            ),

            /// Save Icon Section
            if (serviceLocator<SessionViewModel>().hasCloudAccess())
              Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(width: 1, color: context.colorScheme.elevation2),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.cloudUpload,
                    size: 24,
                    color: Theme.of(context).colorScheme.primaryWhite,
                  ),
                  tooltip: 'Upload project',
                  onPressed: () async {
                    FusionUiUtils.showLoader(context);

                    await serviceLocator<ProjectSyncViewModel>().uploadProject(
                      projectData: serviceLocator<ProjectViewModel>().getCurrentProjectData()!,
                    );
                    if (context.mounted) {
                      FusionUiUtils.hideLoader(context);
                    }
                  },
                ),
              ),

            /// Share Icon Section
            // SemanticHelper.button(
            //   testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.bugReport),
            //   child: Container(
            //     width: 56,
            //     height: 48,
            //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            //     decoration: BoxDecoration(
            //       color: Theme.of(context).colorScheme.primaryWhite,
            //       // border horizontal
            //       border: Border(
            //         left: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
            //         right: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
            //       ),
            //     ),
            //     child: Tooltip(
            //       message: 'Give Feedback',
            //       child: InkWell(
            //         child: Icon(
            //           Icons.feedback_outlined,
            //           size: 24,
            //           color: Theme.of(context).colorScheme.primaryBlack,
            //         ),
            //         onTap: () async {
            //           showDialog(
            //             context: context,
            //             builder:
            //                 (BuildContext context) => const Dialog(
            //                   child: FeedbackWebView(),
            //                 ),
            //           );
            //         },
            //       ),
            //     ),
            // child: Image.asset(
            //   "assets/images/share_icon.png",
            //   width: 24,
            //   height: 24,
            // ),
            // ),
            // ),

            /// Meter Icon Section
            if (serviceLocator<SharedPreferencesHandler>().getBool(SharedPreferenceKeys.enableDevMode) ?? false)
              Container(
                width: 56,
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(width: 1, color: context.colorScheme.elevation2),
                  ),
                ),
                child: Tooltip(
                  message: 'ZMQ meter data',
                  child: InkWell(
                    child: Icon(
                      Icons.electric_meter_outlined,
                      size: 24,
                      color: Theme.of(context).colorScheme.primaryWhite,
                    ),
                    onTap: () async {
                      showMeterDataPopup(context);
                    },
                  ),
                ),
                // child: Image.asset(
                //   "assets/images/share_icon.png",
                //   width: 24,
                //   height: 24,
                // ),
              ),

            /// Share Icon Section
            Container(
              width: 56,
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(width: 1, color: context.colorScheme.elevation2),
                ),
              ),
              child: Tooltip(
                message: 'Feedback and bug reports',
                child: InkWell(
                  child: Icon(
                    Icons.feedback_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.primaryWhite,
                  ),
                  onTap: () async {
                    handleExportLogs(context);
                  },
                ),
              ),
              // child: Image.asset(
              //   "assets/images/share_icon.png",
              //   width: 24,
              //   height: 24,
              // ),
            ),
            ControlDesignTabSwitcher(
              onTabChanged: (int index) {
                serviceLocator<ProjectViewModel>().toggleControlMode();
              },
            ),

            /// App Build Version
            Container(
              height: double.maxFinite,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),

              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(width: 1, color: context.colorScheme.elevation2),
                ),
              ),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (BuildContext context, AsyncSnapshot<PackageInfo> asyncSnapshot) {
                  String appVersion = 'v1.0.0';

                  final PackageInfo? packageInfo = asyncSnapshot.data;
                  if (packageInfo != null) {
                    appVersion = 'v${packageInfo.version}-${packageInfo.buildNumber}';
                  }

                  return FusionAppText(
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.textGrey,
                    ),
                    text: "Build- $appVersion",
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProjectJsonDialog(BuildContext context) {
    serviceLocator<ProjectViewModel>().saveProject();

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final Map<String, dynamic> jsonMap = serviceLocator<ProjectViewModel>().getProjectJson();
    final String prettyJson = encoder.convert(jsonMap);

    showDialog(
      context: context,
      builder:
          (BuildContext ctx) => CleanDialog(
            title: 'Project Saved!',
            actions: <Widget>[
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.close),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const FusionAppText(
                    text: 'Close',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 600,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  prettyJson,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
