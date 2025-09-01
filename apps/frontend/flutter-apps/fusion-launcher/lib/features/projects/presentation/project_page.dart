import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/utils/broadcast_controllers.dart';
import 'package:fusion_launcher/features/bill_of_materials/presentation/bill_of_materials_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_properties/project_properties_view_model.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';

import '../../../core/service_locator.dart';
import '../../../core/utils/fusion_utils.dart';
import '../../../core/widgets/clean_widgets.dart';
import '../../../core/widgets/keep_alive_wrapper.dart';
import '../../configuration/presentation/pages/audio_system_design_page.dart';
import '../../schematics/presentation/pages/schematics_page.dart';
import '../../venue_design/presentation/pages/venue_design_page.dart';
import '../widget/control_design_tab_switcher.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  StreamSubscription<int>? subscription;
  late TextEditingController _projectNameController;

  final List<Widget> _tabs = const <Widget>[
    Tab(text: 'Building'),
    Tab(text: 'Schematics'),
    Tab(text: 'Budget'),
    Tab(text: 'Configuration'),
    Tab(text: 'Cloud'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      animationDuration: Duration.zero,
    );

    subscription = projectTabBroadcastController.stream.listen((int index) {
      if (index >= 0 && index < _tabController.length) {
        _tabController.animateTo(index);
      }
    });
    _projectNameController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    subscription?.cancel();
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100), // Adjust total height as needed
        child: Container(
          color: Colors.black87,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                // Project name section
                BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                  listener: (BuildContext context, ProjectViewModelState state) {
                    // TODO: implement listener
                  },
                  builder: (BuildContext context, ProjectViewModelState state) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            // back button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    serviceLocator<ProjectViewModel>().closeProject();
                                    Navigator.of(context).pop();
                                  },
                                  tooltip: 'Back to projects',
                                ),
                              ),
                            ),
                            IntrinsicWidth(
                              child: TextField(
                                controller: _projectNameController,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Project Name',
                                  suffixIcon: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  suffixIconConstraints: BoxConstraints(
                                    minWidth: 0,
                                    minHeight: 0,
                                  ),
                                ),
                                onSubmitted: (String value) {
                                  serviceLocator<ProjectViewModel>().setProjectName(value.trim());
                                },
                              ),
                            ),
                          ],
                        ),

                        // const Spacer(),
                        Row(
                          children: <Widget>[
                            if (!serviceLocator<ProjectViewModel>().isAdminLogin)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.cloud_upload,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Sync project to cloud',
                                  onPressed: () async {
                                    FusionUtils.showLoader(context);

                                    await serviceLocator<ProjectViewModel>().saveProjectToLocal();
                                    if (context.mounted) {
                                      FusionUtils.hideLoader(context);
                                      // ScaffoldMessenger.of(context).showSnackBar(
                                      //   SnackBar(
                                      //     content: Text(message),
                                      //     backgroundColor: success ? Colors.green : Colors.red,
                                      //     duration: const Duration(seconds: 2),
                                      //   ),
                                      // );
                                    }
                                  },
                                  // onLongPress: () => projectManager.deleteProject(),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                                tooltip: 'Save project',
                                onPressed: () => _showProjectJsonDialog(context),
                                onLongPress: () => serviceLocator<ProjectViewModel>().deleteCurrentProjectFromLocal(),
                              ),
                            ),

                            //circular profile icon
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Container(
                                width: 25,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 1),
                                ),
                                child: const CircleAvatar(
                                  radius: 13, // (28 - 2) / 2 to account for border
                                  backgroundImage: AssetImage("assets/images/fusion_default_icon.png"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                // TabBar section
                Container(
                  height: 50,

                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black26,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: TabBar(
                            dividerColor: Colors.transparent,
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorColor: Colors.black,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: Colors.black87,
                            unselectedLabelColor: Colors.grey[500],
                            labelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            labelPadding: const EdgeInsets.only(left: 32),
                            tabs: _tabs,
                          ),
                        ),
                      ),

                      //Switch to toggle between tabs "Design" and "Cloud"
                      Container(
                        //add a underline to the switcher
                        margin: const EdgeInsets.only(right: 5),
                        child: const ControlDesignTabSwitcher(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          const KeepAliveWrapper(
            child: FloorPlanProjectEditor(),
          ),
          const KeepAliveWrapper(
            child: SchematicsPage(),
          ),
          const KeepAliveWrapper(
            child: BillOfMaterialsPage(),
          ),
          const KeepAliveWrapper(
            child: AudioSystemDesignPage(),
          ),
          // KeepAliveWrapper(
          // FusionCloudWebView(
          //   pageToRedirect:
          //       "embed/projects/${projectManager.value.cloudId}?token=${serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.accessToken)}",
          // ),
          // ),
        ],
      ),
    );
  }

  void _showProjectJsonDialog(BuildContext context) {
    serviceLocator<ProjectViewModel>().saveProjectToLocal();

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final Map<String, dynamic> jsonMap = serviceLocator<ProjectViewModel>().getProjectJson();
    final String prettyJson = encoder.convert(jsonMap);

    showDialog(
      context: context,
      builder:
          (BuildContext ctx) => CleanDialog(
            title: 'Project Saved!',
            actions: <Widget>[
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
