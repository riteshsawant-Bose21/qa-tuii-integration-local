import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class CreateNewProjectViewmodel extends Cubit<NewProjectDetails> {
  CreateNewProjectViewmodel() : super(NewProjectDetails(name: '', metadata: ProjectMetaData.empty()));

  bool isEditMode = false;

  void init({bool isEditMode = false}) {
    this.isEditMode = isEditMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditMode) {
        final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
        final String currentProjectName = projectViewModel.projectName;
        final ProjectMetaData? currentProjectMetaData = projectViewModel.projectMetaData;
        emit(NewProjectDetails(name: currentProjectName, metadata: currentProjectMetaData ?? ProjectMetaData.empty()));
      }
    });
  }

  void updateMetaData(ProjectMetaData updatedState) => emit(state.copyWith(metadata: updatedState));

  void update(NewProjectDetails updatedState) => emit(updatedState);

  void onSubmit(BuildContext context) {
    if (isEditMode) {
      updateProject(context);
    } else {
      saveProject(context);
    }
  }

  void saveProject(BuildContext context) async {
    try {
      FusionUiUtils.showLoader(context);
      final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
      final ProjectData? projectData = await projectViewModel.createAndSaveNewProject(state);
      if (context.mounted) FusionUiUtils.hideLoader(context);
      projectViewModel.openProject(projectData!.id);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) FusionUiUtils.hideLoader(context);
    }
  }

  void updateProject(BuildContext context) async {
    try {
      FusionUiUtils.showLoader(context);
      final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
      projectViewModel.setProjectName(name: state.name);
      projectViewModel.updateProjectMetaData(metaData: state.metadata);
      if (context.mounted) FusionUiUtils.hideLoader(context);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) FusionUiUtils.hideLoader(context);
    }
  }
}
