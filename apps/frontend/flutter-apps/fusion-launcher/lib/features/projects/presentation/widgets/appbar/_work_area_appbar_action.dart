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
    // final Map<String, dynamic> jsonMap = serviceLocator<ProjectViewModel>().getDroInputData().toJson();
    final Map<String, dynamic> jsonMap = serviceLocator<ProjectViewModel>().getProjectJson();

    showDialog(
      context: context,
      builder: (BuildContext ctx) => _ProjectJsonDialog(jsonMap: jsonMap),
    );
  }
}

/// Dialog widget for displaying project JSON with collapse/expand functionality
class _ProjectJsonDialog extends StatefulWidget {
  final Map<String, dynamic> jsonMap;

  const _ProjectJsonDialog({required this.jsonMap});

  @override
  State<_ProjectJsonDialog> createState() => _ProjectJsonDialogState();
}

class _ProjectJsonDialogState extends State<_ProjectJsonDialog> {
  final Set<String> _expandedPaths = <String>{};
  bool _isAllExpanded = false;

  void _collapseAll() {
    setState(() {
      _expandedPaths.clear();
      _isAllExpanded = false;
    });
  }

  void _expandAll() {
    setState(() {
      _expandedPaths.clear();
      _addAllPaths(widget.jsonMap, '');
      _isAllExpanded = true;
    });
  }

  void _addAllPaths(dynamic json, String parentPath) {
    if (json is Map<String, dynamic>) {
      for (final String key in json.keys) {
        final String path = parentPath.isEmpty ? key : '$parentPath.$key';
        _expandedPaths.add(path);
        _addAllPaths(json[key], path);
      }
    } else if (json is List<dynamic>) {
      _expandedPaths.add(parentPath);
      for (int i = 0; i < json.length; i++) {
        _addAllPaths(json[i], '$parentPath[$i]');
      }
    }
  }

  void _togglePath(String path) {
    setState(() {
      if (_expandedPaths.contains(path)) {
        _expandedPaths.remove(path);
        _isAllExpanded = false;
      } else {
        _expandedPaths.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CleanDialog(
      title: 'Project Saved!',
      actions: <Widget>[
        SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, 'collapse_expand_json'),
          child: ElevatedButton.icon(
            onPressed: _isAllExpanded ? _collapseAll : _expandAll,
            icon: Icon(
              _isAllExpanded ? Icons.unfold_less : Icons.unfold_more,
              size: 18,
            ),
            label: FusionAppText(
              text: _isAllExpanded ? 'Collapse All' : 'Expand All',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.close),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
          child: _JsonNode(
            keyName: null,
            value: widget.jsonMap,
            path: '',
            expandedPaths: _expandedPaths,
            onToggle: _togglePath,
            isLast: true,
            depth: 0,
          ),
        ),
      ),
    );
  }
}

/// Optimized JSON node widget - only builds children when expanded
class _JsonNode extends StatelessWidget {
  final String? keyName;
  final dynamic value;
  final String path;
  final Set<String> expandedPaths;
  final void Function(String) onToggle;
  final bool isLast;
  final int depth;

  const _JsonNode({
    required this.keyName,
    required this.value,
    required this.path,
    required this.expandedPaths,
    required this.onToggle,
    required this.isLast,
    required this.depth,
  });

  static const TextStyle _keyStyle = TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF7B1FA2));
  static const TextStyle _braceStyle = TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF616161));
  static const TextStyle _stringStyle = TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFC62828));
  static const TextStyle _numberStyle = TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF2E7D32));
  static const TextStyle _boolStyle = TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFEF6C00));
  static const TextStyle _summaryStyle = TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF1565C0));

  @override
  Widget build(BuildContext context) {
    final String comma = isLast ? '' : ',';

    if (value is Map<String, dynamic>) {
      return _buildObject(value as Map<String, dynamic>, comma);
    } else if (value is List<dynamic>) {
      return _buildArray(value as List<dynamic>, comma);
    } else {
      return _buildPrimitive(comma);
    }
  }

  Widget _buildObject(Map<String, dynamic> map, String comma) {
    final bool isExpanded = path.isEmpty || expandedPaths.contains(path);
    final String nodePath = path.isEmpty ? '' : path;

    if (map.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (keyName != null) Text('"$keyName": ', style: _keyStyle),
          Text('{}$comma', style: _braceStyle),
        ],
      );
    }

    if (!isExpanded && path.isNotEmpty) {
      return _buildCollapsedRow(
        icon: Icons.chevron_right,
        prefix: keyName != null ? '"$keyName": ' : '',
        summary: '{ ${map.length} keys }$comma',
        onTap: () => onToggle(nodePath),
      );
    }

    final List<String> keys = map.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildExpandedHeader(
          icon: Icons.expand_more,
          prefix: keyName != null ? '"$keyName": ' : '',
          bracket: '{',
          onTap: path.isNotEmpty ? () => onToggle(nodePath) : null,
        ),
        ...List<Widget>.generate(keys.length, (int i) {
          final String k = keys[i];
          final String childPath = path.isEmpty ? k : '$path.$k';
          return Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _JsonNode(
              keyName: k,
              value: map[k],
              path: childPath,
              expandedPaths: expandedPaths,
              onToggle: onToggle,
              isLast: i == keys.length - 1,
              depth: depth + 1,
            ),
          );
        }),
        Text('}$comma', style: _braceStyle),
      ],
    );
  }

  Widget _buildArray(List<dynamic> list, String comma) {
    final bool isExpanded = expandedPaths.contains(path);

    if (list.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (keyName != null) Text('"$keyName": ', style: _keyStyle),
          Text('[]$comma', style: _braceStyle),
        ],
      );
    }

    if (!isExpanded) {
      return _buildCollapsedRow(
        icon: Icons.chevron_right,
        prefix: keyName != null ? '"$keyName": ' : '',
        summary: '[ ${list.length} items ]$comma',
        onTap: () => onToggle(path),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildExpandedHeader(
          icon: Icons.expand_more,
          prefix: keyName != null ? '"$keyName": ' : '',
          bracket: '[',
          onTap: () => onToggle(path),
        ),
        ...List<Widget>.generate(list.length, (int i) {
          final String childPath = '$path[$i]';
          return Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _JsonNode(
              keyName: null,
              value: list[i],
              path: childPath,
              expandedPaths: expandedPaths,
              onToggle: onToggle,
              isLast: i == list.length - 1,
              depth: depth + 1,
            ),
          );
        }),
        Text(']$comma', style: _braceStyle),
      ],
    );
  }

  Widget _buildPrimitive(String comma) {
    String text;
    TextStyle style;

    if (value == null) {
      text = 'null';
      style = _boolStyle;
    } else if (value is bool) {
      text = value.toString();
      style = _boolStyle;
    } else if (value is num) {
      text = value.toString();
      style = _numberStyle;
    } else if (value is String) {
      final String v = value as String;
      text = '"${v.length > 80 ? '${v.substring(0, 80)}...' : v}"';
      style = _stringStyle;
    } else {
      text = value.toString();
      style = _braceStyle;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(width: 18),
        if (keyName != null) Text('"$keyName": ', style: _keyStyle),
        Flexible(child: SelectableText('$text$comma', style: style)),
      ],
    );
  }

  Widget _buildCollapsedRow({
    required IconData icon,
    required String prefix,
    required String summary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFF1565C0)),
            const SizedBox(width: 2),
            if (prefix.isNotEmpty) Text(prefix, style: _keyStyle),
            Text(summary, style: _summaryStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedHeader({
    required IconData icon,
    required String prefix,
    required String bracket,
    VoidCallback? onTap,
  }) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF1565C0)),
        const SizedBox(width: 2),
        if (prefix.isNotEmpty) Text(prefix, style: _keyStyle),
        Text(bracket, style: _braceStyle),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: content,
        ),
      );
    }
    return content;
  }
}
