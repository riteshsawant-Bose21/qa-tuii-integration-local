import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/fussion_popup.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

import '../controller/guide_showcase_controller.dart';

class GuideShowcaseWrapper extends StatelessWidget {
  final GuideShowCaseSteps step;
  final Widget child;
  final VoidCallback? onHighlightedSpotTap;
  final bool show;

  const GuideShowcaseWrapper({
    super.key,
    required this.step,
    required this.child,
    this.onHighlightedSpotTap,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    final GuideShowCaseController controller = context.watch<GuideShowCaseController>();
    // Only show if this is the current step and not completed
    final bool shouldShow = controller.shouldShowStep(step);

    if (!show || !shouldShow) return child;

    return FussionPopup(
      show: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      spotlightBorderRadius: 12.0,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.3,
        ),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Step indicator
            Row(
              spacing: 10,
              children: <Widget>[
                Expanded(
                  child: FusionAppText(
                    text: 'Step ${GuideShowCaseSteps.values.indexOf(step) + 1} of ${GuideShowCaseSteps.values.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    context.read<GuideShowCaseController>().skipGuide();
                    Navigator.pop(context);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: FusionAppText(
                    text: 'skip',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            FusionAppText(text: step.description),
          ],
        ),
      ),
      onSpotTap: () {
        Navigator.pop(context);
        onHighlightedSpotTap?.call();
      },
      child: child,
    );
  }

  static void askGuideNeededDialog(BuildContext context) {
    final bool isGuideCompleted = context.read<GuideShowCaseController>().isGuideCompleted;

    if (!isGuideCompleted) return;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Do you want guide to how to use Fussion Launcher ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'ake a short tour to understand how Fussion Launcher works and make the most of it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            FusionOutlinedButton(
              height: 32,
              width: 80,
              label: "No",
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            FusionButton(
              height: 32,
              width: 80,
              label: "Yes",
              activeBackgroundColor: Theme.of(context).colorScheme.primary,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 12,
                color: Colors.white,
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<GuideShowCaseController>().guideNeeded();
              },
            ),
          ],
        );
      },
    );
  }
}
