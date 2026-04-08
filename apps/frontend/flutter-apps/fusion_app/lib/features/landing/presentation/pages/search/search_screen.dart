import 'package:flutter/material.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/core/utils/fusion_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_app/features/landing/presentation/pages/search/recent_search_screen.dart';
import 'package:fusion_app/features/landing/presentation/pages/search/results_screen.dart';
import 'package:fusion_app/features/landing/viewmodel/project_view_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar_search.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SearchProjectsScreen extends StatefulWidget {
   const SearchProjectsScreen({super.key});

  @override
  State<SearchProjectsScreen> createState() => _SearchProjectsScreenState();
}

class _SearchProjectsScreenState extends State<SearchProjectsScreen> {
  final int MIN_SEARCH_LENGTH =2;
   final TextEditingController _searchController = TextEditingController();
   final List<String> recent = [];

   @override
   void initState() {

     serviceLocator<ProjectViewModel>().loadAllLocalProjects();
     Future.delayed(Duration(seconds: 2),(){

       recent.addAll([
         "Gold’s Gym",
         "Planet Fitness",
         "Anytime Fitness",
       ]);
       if(mounted){
         setState(() {

         });
       }
     });

     searchListener();



     super.initState();
   }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        bottom: false,
        child: Scaffold(
          backgroundColor: context.colorScheme.primaryBlack,
          appBar: SearchAppBar(hint: 'Search Project...',controller: _searchController),
          body:  getProjectView(
              builder:(List<ProjectData> projects)  {
                if(_searchController.text.isEmpty) {
                  return RecentSearchScreen(recent: recent,onClear: (){
                    setState(() {
                      recent.clear();
                    });
                  });
                }
                return ResultsScreen(projects: projects.where((item) => item.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList());
              })
        ));
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
         }
         return builder(loadedProjects);
       },
     );
   }

  void searchListener() {


    _searchController.addListener(()async{

      GlobalLoader().hide();
      GlobalLoader().show(context);
      await Future.delayed(Duration(milliseconds: 200));
      setState(() {

      });
      await Future.delayed(Duration(milliseconds: 200));
      GlobalLoader().hide();
    });
  }




   // List<ProjectData> get getProjects {
   //   late List<ProjectData> projects;
   //
   //   final List<ProjectData> allProjects = serviceLocator<ProjectViewModel>().allProjects;
   //
   //   // ================ SEARCH PROJECTS IF QUERY IS NOT EMPTY ==========================
   //   final String searchQuery = _searchController.text.trim().toLowerCase();
   //   if (searchQuery.isNotEmpty && searchQuery.length >= MIN_SEARCH_LENGTH) {
   //     final List<ProjectData> allProjects = serviceLocator<ProjectViewModel>().allProjects;
   //     projects = allProjects.where((ProjectData project) => project.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
   //   } else {
   //     // ======= SHOW ALL PROJECTS IF QUERY IS EMPTY ==========
   //     projects = allProjects;
   //   }
   //
   //   return projects;
   // }
}


