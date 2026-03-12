import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_lib/fusion_widgets/shared_widgets/project/confirmation_dialog.dart';
import 'package:fusion_web/features/projects/presentation/dialogs/invite_user_dialog.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/invite_user_viewmodel.dart';

class ProjectActionsHandler {
  static void invite({
    required BuildContext context,
    required ProjectModel project,
    required ProjectsViewModel viewModel,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider(
          create: (_) => InviteUserCubit(repository: viewModel.repository),
          child: InviteUserDialog(project: project),
        );
      },
    );
  }

  //  ================= DELETE =================
  static Future<bool> delete({
    required BuildContext context,
    required ProjectModel project,
    required ProjectsViewModel viewModel,
  }) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (_) {
        return ConfirmationDialog(
          title: "Delete Project?",
          description:
              "This action cannot be undone. The project will be permanently removed.",
          confirmText: "Delete",
          isDestructive: true,
          onConfirm: () async {
            confirmed = true;
            await viewModel.deleteProject(project.id);
          },
        );
      },
    );

    return confirmed;
  }

  // ================= ARCHIVE =================
  static Future<bool> archive({
    required BuildContext context,
    required ProjectModel project,
    required ProjectsViewModel viewModel,
  }) async {
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (_) {
        return ConfirmationDialog(
          title: "Archive Project?",
          description:
              "The project will be removed from active projects but can be restored later.",
          confirmText: "Archive",
          onConfirm: () async {
            confirmed = true;
            await viewModel.archiveProject(project.id);
          },
        );
      },
    );

    return confirmed;
  }
}
