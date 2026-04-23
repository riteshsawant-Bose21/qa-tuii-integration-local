import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A reusable right-side drawer dialog.
///
/// Displays a titled panel that slides in from the right with user-provided
/// content and an optional action button at the bottom.
class FusionDrawer extends StatelessWidget {
  FusionDrawer({
    required this.semanticId,
    super.key,
    required this.title,
    required this.content,
    this.width = 406,
    this.buttonLabel,
    this.onButtonPressed,
    this.onClose,
    this.backgroundColor,
  });

  ///SemanticId for automation
  final String semanticId;

  /// Header title shown at the top of the drawer.
  final String title;

  /// Drawer Backgroung Color
  final Color? backgroundColor;

  /// The body content of the drawer (scrollable).
  final Widget content;

  /// Width of the drawer.
  final double width;

  /// Optional button label. If null, no button is shown.
  final String? buttonLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onButtonPressed;

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
            _buildHeader(context),
            Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
            Expanded(
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_drawer_content'),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                    boxShadow: [
                      BoxShadow(color: context.colorScheme.shadowDark, blurRadius: 7, offset: const Offset(2, 2)),
                      BoxShadow(color: context.colorScheme.shadowLight, blurRadius: 7, offset: const Offset(-2, -2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: FusionAppButton(
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
          right: 16,
          left: 16,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: title.toUpperCase(),
                semanticId: '${semanticId}_drawer_header_title',
                style: Theme.of(context).textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
              ),
            ),
            GestureDetector(
              onTap: onClose ?? () => Navigator.of(context).maybePop(),
              child: FusionIcon.icon(semanticId: '${semanticId}_drawer_close_icon', Icons.close, size: 16, color: context.colorScheme.iconWhite),
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
    required String title,
    required Widget content,
    double width = 406,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
    Color? backgroundColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
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
                width: width,
                buttonLabel: buttonLabel,
                onButtonPressed: onButtonPressed,
                onClose: () => Navigator.of(ctx).pop(),
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
