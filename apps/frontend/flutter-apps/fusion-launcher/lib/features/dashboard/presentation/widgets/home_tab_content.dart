import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/utils/fusion_utils.dart';

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();

  @override
  Widget build(BuildContext context) {
    // Make it scalable for larger screens
    final double headlineFontSize = MediaQuery.of(context).size.width * 0.07;
    final double subHeadingFontSize = MediaQuery.of(context).size.width * 0.02;

    return Row(
      children: <Widget>[
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 100),

                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: "What's new in Fusion",
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: headlineFontSize > 36 ? 36 : headlineFontSize,
                            ),
                          ),
                          FusionAppText(
                            text: "Stay ahead with the latest updates, feature plug-ins and new enhancements designed to expand your Fusion experience.",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: FusionDarkColorPallette.medium50,
                              fontSize: subHeadingFontSize > 16 ? 16 : subHeadingFontSize,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 60,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: FusionAppText(
                                    text: 'Explore More',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    height: 28,
                                    width: 47,
                                    decoration: BoxDecoration(
                                      color: FusionDarkColorPallette.green20,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      LucideIcons.arrowRight,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 24),

                // ==============================
                //   Recent Projects
                // ==============================
                const _RecentProjects(),
                const SizedBox(height: 16),

                // ==============================
                //   Case Studies and Templates
                // ==============================
                const _CaseStudiesAndTemplates(),
              ],
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: const _HomeRightContent(),
        ),
      ],
    );
  }
}

class _RecentProjects extends StatelessWidget {
  const _RecentProjects();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16).copyWith(bottom: 0),
            child: Row(
              children: <Widget>[
                /// Recent Projects
                Expanded(
                  child: FusionAppText(
                    text: 'RECENT PROJECTS',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          BlocConsumer<ProjectViewModel, ProjectViewModelState>(
            listener: (BuildContext context, ProjectViewModelState state) {
              if (state is ProjectLoaded && context.mounted) {
                if (state.currentProject != null) {
                  FusionUiUtils.hideLoader(context);
                  Navigator.pushNamed(
                    context,
                    Routes.projectPage,
                  ).then((_) async {
                    await serviceLocator<ProjectViewModel>().loadAllLocalProjects();
                  });
                }
              }
              if (state is OpenProjectError && context.mounted) {
                FusionUiUtils.hideLoader(context);
                FusionToast.show(context, message: state.message);
              }
            },
            builder: (BuildContext context, ProjectViewModelState state) {
              if (state is! ProjectLoading && !serviceLocator<ProjectViewModel>().hasProjects) {
                return Center(
                  child: SizedBox(
                    width: 262,
                    height: 166,
                    child: Center(
                      child: FusionAppText(
                        text: "No Projects Available",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final List<ProjectData> projects = serviceLocator<ProjectViewModel>().allProjects;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 16,
                  children: List<Widget>.generate(
                    projects.length,
                    (int index) {
                      final ProjectData project = projects[index];

                      return GestureDetector(
                        onTap: () async {
                          FusionUiUtils.showLoader(context);
                          serviceLocator<ProjectViewModel>().openProject(project.id);
                        },
                        child: _BuildProjectCard(
                          title: project.projectName,
                          onDelete: () => serviceLocator<ProjectViewModel>().deleteProjectFromLocal(project.id),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CaseStudiesAndTemplates extends StatelessWidget {
  const _CaseStudiesAndTemplates();

  static final List<Map<String, String>> templates = <Map<String, String>>[
    <String, String>{
      'title': 'Gym Template',
      'subtitle':
          "A comprehensive template for gym and fitness center projects. This template includes optimized layouts for workout zones, equipment placement, and member flow patterns. Perfect for designing commercial gyms, personal training studios, or home fitness spaces with professional-grade planning tools.",
      'templatePath': 'assets/images/floor_plans/gym_floor_template.png',
    },
    <String, String>{
      'title': 'Restaurant Template',
      'subtitle':
          "A versatile template designed for restaurant and dining establishment projects. Features carefully planned seating arrangements, kitchen workflows, and service areas to maximize efficiency and customer experience. Ideal for cafes, fine dining restaurants, fast-casual establishments, or food courts with customizable layouts.",
      'templatePath': 'assets/images/floor_plans/restaurant_floor_template.png',
    },
    <String, String>{
      'title': 'Retail Store Template',
      'subtitle':
          "A modern template tailored for retail and commercial store projects. Incorporates strategic product placement zones, customer traffic flow optimization, and point-of-sale positioning. Suitable for boutiques, department stores, specialty shops, or pop-up retail spaces with flexible merchandising areas.",
      'templatePath': 'assets/images/floor_plans/retail_floor_template.png',
    },

    <String, String>{
      'title': 'Office Template',
      'subtitle':
          "A professional template for corporate and office workspace projects. Includes collaborative spaces, private offices, meeting rooms, and open work areas designed for productivity and employee comfort. Perfect for startups, established businesses, co-working spaces, or remote work hubs with scalable configurations.",
      'templatePath': 'assets/images/floor_plans/office_floor_template.png',
    },
    <String, String>{
      'title': 'Theater Template',
      'subtitle':
          "An entertainment-focused template for home theater and media room projects. Features optimized seating arrangements, acoustic considerations, and equipment placement for the ultimate viewing experience. Ideal for residential home theaters, media rooms, game rooms, or entertainment spaces with premium audio-visual setups.",
      'templatePath': 'assets/images/floor_plans/theater_template.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16).copyWith(bottom: 0),
            child: Row(
              children: <Widget>[
                /// Recent Projects
                Expanded(
                  child: FusionAppText(
                    text: 'CASE STUDIES & TEMPLATES',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 16,
              children: List<Widget>.generate(
                templates.length,
                (int index) {
                  final Map<String, String> template = templates[index];

                  final String title = template['title']!;
                  final String subtitle = template['subtitle']!;
                  final String assetPath = template['templatePath']!;

                  return GestureDetector(
                    onTap: () async {
                      // FusionUiUtils.showLoader(context);
                      // serviceLocator<ProjectViewModel>().openProject(project.id);
                    },
                    child: _BuildProjectCard(
                      title: title,
                      subtitle: subtitle,
                      assetPath: assetPath,
                      showMore: false,
                      onDelete: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildProjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onDelete;
  final String? assetPath;
  final bool showMore;

  const _BuildProjectCard({
    required this.title,
    this.subtitle,
    required this.onDelete,
    this.assetPath,
    this.showMore = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 268,
      height: 178,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FittedBox(
                        child: Image.asset(
                          assetPath ?? "assets/images/floor_plans/floor_plan_placeholder.png",
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FusionAppText(
                            text: title,
                            maxLine: 1,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          if (subtitle != null) ...<Widget>[
                            Tooltip(
                              message: subtitle!,
                              textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.2),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), width: 0.3),
                              ),
                              child: FusionAppText(
                                text: subtitle!,
                                maxLine: 1,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (showMore)
              Positioned(
                top: 6,
                right: 6,
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'delete') onDelete();
                  },
                  tooltip: "", // Remove default tooltip
                  padding: EdgeInsets.zero,
                  menuPadding: const EdgeInsets.only(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(LucideIcons.trash),
                            SizedBox(width: 8),
                            FusionAppText(text: 'Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_vert),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeRightContent extends StatelessWidget {
  const _HomeRightContent();
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[],
    );
  }
}
