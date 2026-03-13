import 'package:flutter/material.dart';
import 'package:fusion_app/features/landing/presentation/widgets/project_slider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class AllProjectsScreen extends StatelessWidget {

  final List<ProjectData> projects;
  const AllProjectsScreen({required this.projects,super.key});

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// All Projects Title
        const SizedBox(height: 24),
        Text(
          "All Your Projects",
          style: Theme.of(context).textTheme.b2Medium!.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.textPrimary,
          ),
        ),

        const SizedBox(height: 16),

        /// Filters
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(context, "All", selected: true),
              _FilterChip(context, "Today"),
              _FilterChip(context, "This Week"),
              _FilterChip(context, "This Month"),
              _FilterChip(context, "Last 3 Months"),
            ],
          ),
        ),

        const SizedBox(height: 16),

        /// Grid
        ProjectSlider(projects: projects)
      ],
    );
  }

  // Widget _ProjectCard(BuildContext context,
  //     {required String title, required String time}) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(24),
  //       color: const Color(0xFF1A1A18),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //
  //         /// Thumbnail
  //         Expanded(
  //           child: Container(
  //             decoration: const BoxDecoration(
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //               color: Color(0xFF2A2926),
  //             ),
  //           ),
  //         ),
  //
  //         /// Title & Time
  //         Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 title,
  //                 style: Theme.of(context).textTheme.titleSmall!.copyWith(
  //                   fontWeight: FontWeight.w600,
  //                   color: context.colorScheme.textPrimary,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //               const SizedBox(height: 6),
  //               Text(
  //                 time,
  //                 style: Theme.of(context).textTheme.titleSmall!.copyWith(
  //                   fontWeight: FontWeight.w400,
  //                   color: context.colorScheme.textSecondary,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _FilterChip(BuildContext context, String label,
      {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        constraints: BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.colorScheme.elevation2 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : context.colorScheme.elevation2,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.l1Regular.copyWith(
            fontWeight: FontWeight.w400,
            color: selected
                ? context.colorScheme.textPrimary
                : context.colorScheme.textSecondary,
          ),
        ),
      ),
    );
  }

}