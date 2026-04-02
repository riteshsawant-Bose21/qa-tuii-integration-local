import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/hover_dropdown.dart';
import 'package:fusion_web/features/projects/presentation/viewmodels/projects_viewmodel.dart';
import 'package:fusion_web/features/projects/presentation/widgets/filter_dropdown.dart';
import 'package:fusion_web/features/projects/presentation/widgets/projects_page_widgets/view_toggle_button.dart';

class ProjectsFilters extends StatelessWidget {
  const ProjectsFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProjectsViewModel>();

    return Container(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              onChanged: vm.updateSearch,
              decoration: InputDecoration(
                labelText: 'Search projects...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: context.colorScheme.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),

                // borderSide: BorderSide(color: darkColorScheme.textPrimary),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: FilterDropdown(
              value: vm.region,
              items: const ['All', 'indoor', 'outdoor', 'hybrid'],
              onChanged: (v) => vm.updateRegion(v!),
              backgroundColor: context.colorScheme.elevation2,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: FilterDropdown(
              value: vm.status,
              items: const ['All', 'Proposal', 'Development', 'Commissioned'],
              onChanged: (v) => vm.updateStatus(v!),
              backgroundColor: context.colorScheme.elevation2,
            ),
          ),

          const SizedBox(width: 16),

          Row(
            children: [
              ViewToggleButton(
                icon: Icons.view_list_rounded,
                isSelected: !vm.isGridView,
                onTap: () => vm.toggleView(false),
              ),
              const SizedBox(width: 8),
              ViewToggleButton(
                icon: Icons.grid_view_rounded,
                isSelected: vm.isGridView,
                onTap: () => vm.toggleView(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
