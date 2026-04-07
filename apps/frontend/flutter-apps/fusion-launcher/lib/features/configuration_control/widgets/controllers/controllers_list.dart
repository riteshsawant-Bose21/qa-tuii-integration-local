import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/controllers/controller_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';

/// Widget displaying the list of controllers
class ControllersList extends StatelessWidget {
  final List<FusionController> controllers;
  final String? selectedControllerId;
  final String searchQuery;

  const ControllersList({
    super.key,
    required this.controllers,
    this.selectedControllerId,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        border: Border(
          right: BorderSide(color: context.colorScheme.strokeLight, width: 1),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: controllers.isEmpty && searchQuery.isNotEmpty ? _buildEmptySearchState(context) : _buildControllersList(context),
    );
  }

  /// Builds the empty state widget when no controllers match the search query
  Widget _buildEmptySearchState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FusionAppText(
          text: 'No controllers match your search',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Builds the list of controllers using a ListView.builder for efficient rendering
  Widget _buildControllersList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controllers.length,
      itemBuilder: (BuildContext context, int index) {
        final FusionController controller = controllers[index];
        final bool isSelected = controller.id == selectedControllerId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ControllerCard(
            controller: controller,
            isSelected: isSelected,
            onTap: () => context.read<ConfigurationControlViewmodel>().selectController(controller.id),
            onDelete: () => context.read<ConfigurationControlViewmodel>().deleteController(controller.id),
          ),
        );
      },
    );
  }
}
