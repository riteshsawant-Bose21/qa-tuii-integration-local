import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/project_card.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/service_locator.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: context.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: headlineFontSize > 36 ? 36 : headlineFontSize,
                            ),
                          ),
                          FusionAppText(
                            text: "Stay ahead with the latest updates, feature plug-ins and new enhancements designed to expand your Fusion experience.",
                            style: context.textTheme.bodyLarge?.copyWith(
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
                              color: context.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: FusionAppText(
                                    text: 'Explore More',
                                    style: context.textTheme.titleSmall?.copyWith(
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

        // ==============================
        //   Getting Started / Right Content
        // ==============================
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
        color: context.colorScheme.surface,
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
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          BlocBuilder<ProjectViewModel, ProjectViewModelState>(
            builder: (BuildContext context, ProjectViewModelState state) {
              if (!serviceLocator<ProjectViewModel>().hasProjects) {
                return Center(
                  child: SizedBox(
                    height: 166,
                    child: Center(
                      child: FusionAppText(
                        text: "No recent projects found.\nCreate a new project to get started!",
                        textAlign: TextAlign.center,
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.4),
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
                        onTap: () => ProjectDetailsDialog.show(context, project: project),
                        child: ProjectCard(
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
        color: context.colorScheme.surface,
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
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.chevronRight,
                      color: context.colorScheme.onSurface.withValues(alpha: 0.4),
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
                    child: ProjectCard(
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

class _HomeRightContent extends StatelessWidget {
  const _HomeRightContent();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        spacing: 10,
        children: <Widget>[
          _buildCard(
            context,
            title: 'Getting Started',
            description: 'Watch our introduction & Training videos!\nTutorials and walkthroughs for our new and existing users.',
            buttonText: 'Start Tutorials',
            onTap: () {},
          ),

          _buildCard(
            context,
            title: 'Build My System',
            description:
                'Build new project with fast product database and cost calculator! Instantly design, estimate and configure your system and see cost updates as you build.',
            buttonText: 'Start Building',
            onTap: () {},
          ),

          _buildCard(
            context,
            title: 'Need Design Assistance',
            description: 'We are here to help and validate your design whenever you need it!',
            buttonText: 'Click for Support',
            onTap: () {},
          ),

          _buildCard(
            context,
            title: 'Sign-Up for In-person Training',
            description: 'Register for hands-on sessions with our experts to deepen your knowledge and gain practical experience.',
            buttonText: 'View Training Courses',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),

          Flexible(
            child: FusionAppText(
              text: description,
              style: context.textTheme.labelSmall?.copyWith(
                color: FusionDarkColorPallette.medium50,
              ),
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.transparent,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FusionAppText(
                    text: buttonText,
                    maxLine: 1,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
