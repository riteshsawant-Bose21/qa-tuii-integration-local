import 'package:flutter/material.dart';
import 'package:fusion_web/core/constants/app_constants.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_lib/fusion_widgets/shared_widgets/project/confirmation_dialog.dart';
import 'package:fusion_web/features/projects/presentation/dialogs/invite_user_dialog.dart';
import 'package:fusion_lib/fusion_widgets/shared_widgets/project/project_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

class ProjectActionsHandler {
  // ================= INVITE =================
  static void invite({
    required BuildContext context,
    required ProjectModel project,
  }) {
    showDialog(
      context: context,
      builder: (_) => InviteUserDialog(project: project),
    );
  }

  //  ================= DELETE =================
  static Future<void> delete({
    required BuildContext context,
    required ProjectModel project,
    required ProjectsViewModel viewModel,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return ConfirmationDialog(
          title: "Delete Project?",
          description:
              "This action cannot be undone. The project will be permanently removed.",
          confirmText: "Delete",
          isDestructive: true,
          onConfirm: () async {
            await viewModel.deleteProject(project.id);

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );
  }

  // ================= ARCHIVE =================
  static void archive({
    required BuildContext context,
    required ProjectModel project,
    required ProjectsViewModel viewModel,
  }) {
    showDialog(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: "Archive Project?",
        description:
            "The project will be removed from active projects but can be restored later.",
        confirmText: "Archive",
        onConfirm: () {
          viewModel.updateProject(project.copyWith(status: "Archived"));
        },
      ),
    );
  }

  // ================= EDIT =================
  static Future<void> edit({
    required BuildContext context,
    required ProjectModel project,
    required ProjectsViewModel viewModel,
  }) async {
    final result = await showDialog<NewProjectFormData>(
      context: context,
      builder: (_) => ProjectDialog(
        initialData: NewProjectFormData(
          name: project.name,
          version: '',
          tags: '',
          author: '',
          organization: project.clientName,
          state: project.region,
          country: '',
          timeZone: '',
          building: '',
          notes: project.description,
        ),
        onSubmit: (formData) {
          Navigator.pop(context, formData);
        },
      ),
    );

    if (result != null) {
      viewModel.updateProject(
        project.copyWith(
          name: result.name,
          description: result.notes,
          clientName: result.organization,
          region: result.state,
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  // ================= CREATE =================
  static Future<void> create({
    required BuildContext context,
    required ProjectsViewModel viewModel,
  }) async {
    final result = await showGeneralDialog<NewProjectFormData>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "New Project",
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return Center(
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
              child: ProjectDialog(
                onSubmit: (formData) {
                  Navigator.pop(context, formData);
                },
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      final newProject = ProjectModel(
        id: const Uuid().v4(),
        name: result.name,
        description: result.notes,
        clientName: result.organization,
        region: result.state,
        status: "proposal",
        lastUpdated: DateTime.now(),
        healthyDevices: 0,
        warningDevices: 0,
        criticalDevices: 0,
        incidents: 0,
      );

      await viewModel.createProject(newProject);
    }
  }
}
