import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_launcher/features/configuration_control/widgets/common/panel_section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Middle panel — PAGES (message tab).
///
/// Each checked message player appears as a page row.
/// The last-checked player is the active (highlighted) page.
/// Tapping a row changes the active page.
class MessagePagesPanel extends StatelessWidget {
  const MessagePagesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) return const SizedBox.shrink();

        // Only checked players appear as pages
        final List<Source> pageItems = state.messagePlayers.where((Source s) => state.selectedMessagePlayerIds.contains(s.id)).toList();

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PanelSectionHeader(title: 'PAGES'),
              Expanded(
                child:
                    pageItems.isEmpty
                        ? Center(
                          child: FusionAppText(
                            text: 'No pages available',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),
                        )
                        : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          children:
                              pageItems.map((Source s) {
                                final bool isActive = state.selectedMessagePageId == s.id;
                                return _PageRow(
                                  label: s.name,
                                  isActive: isActive,
                                  onTap: () => context.read<ConfigurationControlViewmodel>().selectMessagePage(s.id),
                                );
                              }).toList(),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single page row ──────────────────────────────────────────────────────────

class _PageRow extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PageRow({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? context.colorScheme.primaryColor : context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? context.colorScheme.primaryColor : context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.drag_indicator,
              size: 14,
              color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.iconDefault,
            ),
            const SizedBox(width: 2),
            Text(
              ':',
              style: TextStyle(
                fontSize: 11,
                color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FusionAppText(
                text: label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive ? context.colorScheme.primaryWhite : context.colorScheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
