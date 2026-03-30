import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/text_fleld.dart';
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
              decoration: _inputDecoration('Search projects...', Icons.search),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: FilterDropdown(
              value: vm.region,
              items: const ['All', 'indoor', 'outdoor', 'hybrid'],
              onChanged: (v) => vm.updateRegion(v!),
            ),
          ),

          
          const SizedBox(width: 16),

          Expanded(
            child: FilterDropdown(
              value: vm.status,
              items: const ['All', 'Proposal', 'Development', 'Commissioned'],
              onChanged: (v) => vm.updateStatus(v!),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      // labelText: label,
      // prefixIcon: Icon(icon, color: Colors.grey[400]),
      // filled: true,
      // fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
