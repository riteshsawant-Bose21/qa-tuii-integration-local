import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/core/utils/fusion_utils.dart';
import 'package:fusion_app/features/landing/presentation/pages/home/all_projects_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/home/no_projects_screen.dart';
import 'package:fusion_app/features/landing/presentation/widgets/drawer/nav_drawer.dart';
import 'package:fusion_app/features/landing/presentation/widgets/welcome_card.dart';
import 'package:fusion_app/features/landing/viewmodel/project_view_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<ProjectData> dummyProjects = [
  ProjectData(id: '1', name: 'Namiths Gym',
      description: 'Floor 1',
      projectRawData: {},
      createdAt: DateTime.now(),
      updatedAt:  DateTime.now(),
      isCloudInstance: false),
  ProjectData(id: '2', name: 'My Gym',
      description: 'Floor 2',
      projectRawData: {},
      createdAt: DateTime.now(),
      updatedAt:  DateTime.now(),
      isCloudInstance: false),
  ProjectData(id: '3', name: 'His Gym',
      description: 'Floor 3',
      projectRawData: {},
      createdAt: DateTime.now(),
      updatedAt:  DateTime.now(),
      isCloudInstance: false),
  ProjectData(id: '4', name: 'Her Gym',
      description: 'Floor 4',
      projectRawData: {},
      createdAt: DateTime.now(),
      updatedAt:  DateTime.now(),
      isCloudInstance: false),
  ProjectData(id: '5', name: 'Their Gym',
      description: 'Floor 5',
      projectRawData: {},
      createdAt: DateTime.now(),
      updatedAt:  DateTime.now(),
      isCloudInstance: false),
  ProjectData(id: '6', name: 'Gym',
      description: 'Floor 6',
      projectRawData: {},
      createdAt: DateTime.now(),
      updatedAt:  DateTime.now(),
      isCloudInstance: false)
];



class HomeScreen extends StatefulWidget {
   HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  // List<ProjectData> prjs = [
  //   ProjectData(id: '1', name: 'Namiths Gym',
  //       description: 'Floor 1',
  //       projectRawData: {},
  //       createdAt: DateTime.now(),
  //       updatedAt:  DateTime.now(),
  //       isCloudInstance: false),
  //   ProjectData(id: '2', name: 'My Gym',
  //       description: 'Floor 2',
  //       projectRawData: {},
  //       createdAt: DateTime.now(),
  //       updatedAt:  DateTime.now(),
  //       isCloudInstance: false),
  //   ProjectData(id: '3', name: 'His Gym',
  //       description: 'Floor 3',
  //       projectRawData: {},
  //       createdAt: DateTime.now(),
  //       updatedAt:  DateTime.now(),
  //       isCloudInstance: false),
  //   ProjectData(id: '4', name: 'Her Gym',
  //       description: 'Floor 4',
  //       projectRawData: {},
  //       createdAt: DateTime.now(),
  //       updatedAt:  DateTime.now(),
  //       isCloudInstance: false),
  //   ProjectData(id: '5', name: 'Their Gym',
  //       description: 'Floor 5',
  //       projectRawData: {},
  //       createdAt: DateTime.now(),
  //       updatedAt:  DateTime.now(),
  //       isCloudInstance: false),
  //   ProjectData(id: '6', name: 'Gym',
  //       description: 'Floor 6',
  //       projectRawData: {},
  //       createdAt: DateTime.now(),
  //       updatedAt:  DateTime.now(),
  //       isCloudInstance: false)
  // ];

  @override
  void initState() {

    Future.delayed(Duration(seconds: 3),(){
    serviceLocator<ProjectViewModel>().loadAllLocalProjects();
    });
    super.initState();
  }
  static void navigate(String route) {
    Navigator.pushNamed(globalNavigatorKey.currentState!.context, route);
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.colorScheme.primaryBlack,
        drawer: MenuDrawer(),
        appBar: CommonAppBar(title: 'Home',leadingIcon: GestureDetector(
            onTap: (){
              _scaffoldKey.currentState?.openDrawer();
            },
            child:  Icon(Icons.menu,color:context.colorScheme.iconWhite
            )),
            actions:  [
              GestureDetector(
                  onTap: (){
                    navigate(Routes.searchPage);
                  },
                  child: Icon(Icons.search,color: context.colorScheme.iconWhite)),
              SizedBox(width: 16),
            ]),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 16),

              WelcomeSection(),

              getProjectView(
                  builder:(projects) =>  projects.isEmpty ? NoProjectsScreen(): AllProjectsScreen(projects: projects))
            ],
          ),
        ),
      ),
    );
  }

  Widget getProjectView({  required Widget Function(List<ProjectData> projects) builder})
  {
    return BlocConsumer<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        if (state is OpenProjectError && context.mounted) {
          MobileFusionUiUtils.hideLoader(context);
          FusionToast.show(context, message: state.message);
        }
      },
      builder: (BuildContext context, ProjectViewModelState state) {
        List<ProjectData> loadedProjects = [];
        if(state is ProjectLoaded){
          loadedProjects.addAll(state.projects);
        //  loadedProjects.addAll(prjs);
        }

        return builder(loadedProjects);
      },
    );
  }
}