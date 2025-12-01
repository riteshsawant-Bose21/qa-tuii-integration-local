import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/utils/fusion_utils.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/pages/launcher_sign_in_page.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionUtils;
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onDelete;
  final String? assetPath;
  final bool showMore;
  final double? width, height, borderRadius;

  const ProjectCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.onDelete,
    this.assetPath,
    this.showMore = true,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 268,
      height: height ?? 178,
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(borderRadius ?? 6),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.topLeft,
                              child: Image.asset(
                                assetPath ?? "assets/images/floor_plans/floor_plan_placeholder.png",
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(
                            child: FusionAppText(
                              text: title,
                              maxLine: 1,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          if (subtitle != null) ...<Widget>[
                            Flexible(
                              child: Tooltip(
                                message: subtitle!,
                                textStyle: context.textTheme.labelSmall?.copyWith(
                                  color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.2),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.colorScheme.onSurface.withValues(alpha: 0.3), width: 0.3),
                                ),
                                child: FusionAppText(
                                  text: subtitle!,
                                  maxLine: 1,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
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

            if (showMore) ...<Widget>[
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
                  borderRadius: BorderRadius.circular(8),
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                    side: BorderSide(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  color: context.colorScheme.surface,
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
          ],
        ),
      ),
    );
  }
}

class ProjectDetailsDialog extends StatelessWidget {
  final ProjectData project;
  const ProjectDetailsDialog({super.key, required this.project});

  static void show(BuildContext context, {required ProjectData project}) {
    Navigator.of(context).push(
      AnimatedBlurDialogRoute<void>(
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: ProjectDetailsDialog(project: project),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 400.0;
    const double cardWidth = 490.0;
    final double borderRadius = 14;

    return Row(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  color: context.colorScheme.surface.withValues(alpha: 0.5),
                  border: Border.all(color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
                ),
                child: ProjectCard(
                  width: cardWidth,
                  height: cardHeight,
                  title: project.projectName,
                  showMore: false,
                  borderRadius: borderRadius,
                  onDelete: () {},
                ),
              ),
            ),
          ),
        ),

        Flexible(
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: context.colorScheme.surface.withValues(alpha: 0.5),
                border: Border.all(color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                flex: 2,
                                child: FusionAppText(
                                  text: project.projectName,
                                  maxLine: 2,
                                  style: context.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.end,
                                  children: <Widget>[
                                    ...<String>[
                                      // MAX 4 TAGS
                                      "Restaurant",
                                      "Commercial",
                                      "3000 ft2",
                                      "Multi-Zone",
                                    ].map(
                                      (String tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(6),
                                            color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                                          ),
                                          child: FusionAppText(
                                            text: tag,
                                            style: context.textTheme.labelSmall?.copyWith(
                                              color: context.colorScheme.onSurface,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 0),
                          const SizedBox(height: 16),
                          FusionAppText(
                            text: "Project Description:",
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: FusionAppText(
                              text:
                                  "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam dolor amet.",
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          NeumorphicDarkButton(
                            onTap: () {},
                            height: 32,
                            width: 112,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 4,
                              children: <Widget>[
                                Flexible(
                                  child: FusionAppText(
                                    text: "Device List",
                                    style: context.textTheme.labelLarge?.copyWith(
                                      fontSize: 12,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const Icon(LucideIcons.arrowRight),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Flexible(
                                child: NeumorphicDarkButton(
                                  onTap: () {},
                                  height: 32,
                                  width: 168,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 4,
                                    children: <Widget>[
                                      Flexible(
                                        child: FusionAppText(
                                          text: "Collaborators on File",
                                          style: context.textTheme.labelLarge?.copyWith(
                                            fontSize: 12,
                                            color: context.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const Icon(LucideIcons.arrowRight),
                                    ],
                                  ),
                                ),
                              ),
                              Flexible(
                                child: NeumorphicDarkButton(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    FusionUiUtils.showLoader(context);
                                    serviceLocator<ProjectViewModel>().openProject(project.id);
                                  },
                                  height: 32,
                                  width: 168,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 4,
                                    children: <Widget>[
                                      Flexible(
                                        child: FusionAppText(
                                          text: "Open Project",
                                          style: context.textTheme.labelLarge?.copyWith(
                                            fontSize: 12,
                                            color: context.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const Icon(LucideIcons.arrowRight),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedBlurDialogRoute<T> extends PageRoute<T> {
  AnimatedBlurDialogRoute({required this.builder, this.barrierLabel});

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String? barrierLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, _) {
        // Animate blur from 0 → 10
        final double blur = Tween<double>(begin: 0, end: 5).evaluate(animation);

        return Stack(
          children: <Widget>[
            // Animated blur background
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: (animation.value * 0.15),
                  ),
                ),
              ),
            ),

            // Dialog with scale + fade (optional)
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: builder(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get maintainState => true;
}
