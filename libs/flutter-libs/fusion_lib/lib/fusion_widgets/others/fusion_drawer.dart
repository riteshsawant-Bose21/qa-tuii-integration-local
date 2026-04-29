import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A reusable right-side drawer dialog.
///
/// Displays a titled panel that slides in from the right with user-provided
/// content and an optional action button at the bottom.
class FusionDrawer extends StatelessWidget {
  const FusionDrawer({
    required this.semanticId,
    super.key,
    this.title,
    required this.content,
    this.width = 406,
    this.buttonLabel,
    this.onButtonPressed,
    this.onClose,
    this.backgroundColor,
    this.buttonEnabledNotifier,
    this.header,
    this.showBackButton = false,
  }) : assert(
         header != null || title != null,
         'Either a custom header or a title must be provided.',
       );

  final ValueNotifier<bool>? buttonEnabledNotifier;

  ///SemanticId for automation
  final String semanticId;

  /// Header title shown at the top of the drawer.
  /// Not required when a custom [header] widget is provided.
  final String? title;

  /// Drawer Backgroung Color
  final Color? backgroundColor;

  /// The body content of the drawer (scrollable).
  final Widget content;

  /// The header of the drawer.
  /// When provided, [title] is not required.
  final Widget? header;

  /// Width of the drawer.
  final double width;

  /// Optional button label. If null, no button is shown.
  final String? buttonLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onButtonPressed;

  /// When true, shows a back button instead of a close icon in the header.
  final bool showBackButton;

  /// Called when the close icon is tapped. Defaults to popping the route.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_drawer'),
      child: Container(
        width: width,
        color: backgroundColor ?? context.colorScheme.elevation1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            (header ?? _buildHeader(context)),
            Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
            Expanded(
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_drawer_content'),
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
            ),
            if (buttonLabel != null) ...<Widget>[
              Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
              SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_drawer_footer'),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation1,
                    boxShadow: [
                      BoxShadow(color: context.colorScheme.shadowDark, blurRadius: 7, offset: const Offset(2, 2)),
                      BoxShadow(color: context.colorScheme.shadowLight, blurRadius: 7, offset: const Offset(-2, -2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: buttonEnabledNotifier != null
                      ? ValueListenableBuilder<bool>(
                          valueListenable: buttonEnabledNotifier!,
                          builder: (BuildContext context, bool enabled, Widget? child) {
                            return FusionAppButton(
                              height: 48,
                              enabled: enabled,
                              semanticId: '${semanticId}_drawer_footer_button',
                              style: FusionAppButtonStyle.primary,
                              text: buttonLabel!,
                              onPressed: enabled ? onButtonPressed : null,
                            );
                          },
                        )
                      : FusionAppButton(
                          height: 48,
                          semanticId: '${semanticId}_drawer_footer_button',
                          style: FusionAppButtonStyle.primary,
                          text: buttonLabel!,
                          onPressed: buttonLabel != null ? onButtonPressed : null,
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_drawer_header'),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24,
          bottom: 16,
          right: 24,
          left: 24,
        ),
        child: Row(
          children: <Widget>[
            if (showBackButton) ...[
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onClose ?? () => Navigator.of(context).maybePop(),
                  child: FusionIcon.icon(
                    semanticId: '${semanticId}_drawer_back_icon',
                    LucideIcons.arrowLeft200,
                    size: 16,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FusionAppText(
                text: title!.toUpperCase(),
                semanticId: '${semanticId}_drawer_header_title',
                style: Theme.of(context).textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onClose ?? () => Navigator.of(context).maybePop(),
                child: FusionIcon.icon(semanticId: '${semanticId}_drawer_close_icon', Icons.close, size: 16, color: context.colorScheme.iconWhite),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the drawer as a right-aligned modal dialog that slides in.
  static Future<T?> show<T>({
    required BuildContext context,
    required String semanticId,
    String? title,
    required Widget content,
    Widget? header,
    double width = 406,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
    Color? backgroundColor,
    ValueNotifier<bool>? buttonEnabledNotifier,
    bool showBackButton = false,
  }) {
    assert(
      header != null || title != null,
      'Either a custom header or a title must be provided.',
    );
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title ?? semanticId,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (BuildContext ctx, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              height: double.infinity,
              child: FusionDrawer(
                semanticId: semanticId,
                title: title,
                backgroundColor: backgroundColor,
                content: content,
                header: header,
                width: width,
                buttonLabel: buttonLabel,
                onButtonPressed: onButtonPressed,
                showBackButton: showBackButton,
                onClose: () => Navigator.of(ctx).pop(),
                buttonEnabledNotifier: buttonEnabledNotifier,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, Animation<double> anim, __, Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}
