import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path/path.dart';

enum DialogType { success, failure, warning, confirmation }

enum DeviceType { desktop, mobile }

class DialogBox extends StatelessWidget {
  final DialogType type;
  final DeviceType devicetype;
  final String title;
  final String description;
  final String? copyText;
  final String? contactEmail;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool showCopyButton;
  final bool horizontal;
  final bool vertical;
  final FusionAppButtonStyle primaryButtonStyle;
  final FusionAppButtonStyle secondaryButtonStyle;
  const DialogBox({
    Key? key,
    this.devicetype = DeviceType.mobile,
    required this.type,
    required this.title,
    required this.description,
    this.copyText,
    this.contactEmail,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.showCopyButton = false,
    this.horizontal = false,
    this.vertical = false,
    this.secondaryButtonStyle = FusionAppButtonStyle.secondary,
    this.primaryButtonStyle = FusionAppButtonStyle.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "dialog_box_${type}",
      ),
      child: devicetype == DeviceType.desktop
          ? Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 486,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  border: Border.all(
                    color: context.colorScheme.elevation2,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 16.0,
                        right: 16.0,
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            child: Icon(
                              Icons.close,
                              color: context.colorScheme.iconWhite,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 24,
                      ),
                      child: Column(
                        spacing: 5,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (type == DialogType.success) ...[
                            FusionImage.asset(
                              width: 120,
                              height: 120,
                              "packages/fusion_lib/lib/assets/images/dialog_success.png",
                            ),
                          ],
                          if (type == DialogType.warning) ...[
                            FusionImage.asset(
                              width: 120,
                              height: 120,
                              "packages/fusion_lib/lib/assets/images/dialog_warning.png",
                            ),
                          ],
                          if (type == DialogType.confirmation) ...[
                            FusionImage.asset(
                              width: 120,
                              height: 120,
                              "packages/fusion_lib/lib/assets/images/dialog_confirmation.png",
                            ),
                          ],
                          if (type == DialogType.failure) ...[
                            FusionImage.asset(
                              width: 120,
                              height: 120,
                              "packages/fusion_lib/lib/assets/images/dialog_failure.png",
                            ),
                          ],
                          // Title
                          Column(
                            children: [
                              FusionAppText(
                                text: title,
                                style: context.textTheme.h4SemiBold.copyWith(
                                  color: context.colorScheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              // Description
                              Text(
                                description,
                                style: context.textTheme.b3Regular.copyWith(
                                  color: context.colorScheme.textBody,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                          // Copy Text Button (if enabled)
                          if (showCopyButton && copyText != null) ...[
                            _buildCopyButton(context),
                            const SizedBox(height: 16),
                          ],

                          // Contact Info (if provided)
                          if (contactEmail != null) ...[
                            _buildContactInfo(context),
                            const SizedBox(height: 20),
                          ],
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.elevation1,
                    border: Border.all(
                      color: context.colorScheme.elevation2,
                      width: 1,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        child: Icon(
                          Icons.close,
                          color: context.colorScheme.iconWhite,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Dialog(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    width: 486,
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation1,
                      border: Border.all(
                        color: context.colorScheme.elevation2,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Close button
                        Container(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 24,
                          ),
                          child: Column(
                            spacing: 5,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (type == DialogType.success) ...[
                                FusionImage.asset(
                                  width: 120,
                                  height: 120,
                                  "packages/fusion_lib/lib/assets/images/dialog_success.png",
                                ),
                              ],
                              if (type == DialogType.warning) ...[
                                FusionImage.asset(
                                  width: 120,
                                  height: 120,
                                  "packages/fusion_lib/lib/assets/images/dialog_warning.png",
                                ),
                              ],
                              if (type == DialogType.confirmation) ...[
                                FusionImage.asset(
                                  width: 120,
                                  height: 120,
                                  "packages/fusion_lib/lib/assets/images/dialog_confirmation.png",
                                ),
                              ],
                              if (type == DialogType.failure) ...[
                                FusionImage.asset(
                                  width: 120,
                                  height: 120,
                                  "packages/fusion_lib/lib/assets/images/dialog_failure.png",
                                ),
                              ],
                              // Title
                              Column(
                                children: [
                                  FusionAppText(
                                    text: title,
                                    style: context.textTheme.h4SemiBold
                                        .copyWith(
                                          color:
                                              context.colorScheme.textPrimary,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),

                                  // Description
                                  Text(
                                    description,
                                    style: context.textTheme.b3Regular.copyWith(
                                      color: context.colorScheme.textBody,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),

                              // Copy Text Button (if enabled)
                              if (showCopyButton && copyText != null) ...[
                                _buildCopyButton(context),
                                const SizedBox(height: 16),
                              ],

                              // Contact Info (if provided)
                              if (contactEmail != null) ...[
                                _buildContactInfo(context),
                                const SizedBox(height: 20),
                              ],
                              _buildActionButtons(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Copy to clipboard logic
        // Clipboard.setData(ClipboardData(text: copyText!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 219,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(200),
          border: Border.all(
            color: context.colorScheme.elevation3,
            width: 1,
          ),
        ),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Copy Text:',
              style: context.textTheme.b3Regular.copyWith(
                color: context.colorScheme.textBody,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              copyText!.toUpperCase(),
              style: context.textTheme.b3Regular.copyWith(
                color: context.colorScheme.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.copy,
              size: 20,
              color: context.colorScheme.iconWhite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      width: 438,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: context.colorScheme.textPrimary,
            fontSize: 12,
          ),
          children: [
            TextSpan(
              style: context.textTheme.b3Regular.copyWith(
                color: context.colorScheme.textPrimary,
              ),
              text: 'For any queries related to this device, please write to\n',
            ),
            TextSpan(
              text: contactEmail,
              style: context.textTheme.b3Regular.copyWith(
                color: context.colorScheme.infoText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasBothButtons = horizontal == true && vertical == true;

    return Column(
      spacing: 24,
      children: [
        if (hasBothButtons) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FusionAppButton(
                width: 210,
                style: secondaryButtonStyle,
                text: secondaryButtonText,
                onPressed: onSecondaryPressed,
              ),
              const SizedBox(width: 12),
              FusionAppButton(
                width: 210,
                style: primaryButtonStyle,
                text: primaryButtonText,
                onPressed: onPrimaryPressed,
              ),
            ],
          ),
          Column(
            spacing: 12,
            children: [
              FusionAppButton(
                width: 438,
                style: primaryButtonStyle,
                text: primaryButtonText!,
                onPressed: onPrimaryPressed,
              ),
              FusionAppButton(
                width: 438,
                style: secondaryButtonStyle,
                text: secondaryButtonText!,
                onPressed: onSecondaryPressed,
              ),
            ],
          ),
        ] else if (horizontal) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FusionAppButton(
                width: 210,
                style: secondaryButtonStyle,
                text: secondaryButtonText!,
                onPressed: onSecondaryPressed,
              ),
              const SizedBox(width: 12),
              FusionAppButton(
                width: 210,
                style: primaryButtonStyle,
                text: primaryButtonText!,
                onPressed: onPrimaryPressed,
              ),
            ],
          ),
        ] else if (vertical) ...[
          Column(
            spacing: 12,
            children: [
              FusionAppButton(
                width: 438,
                style: primaryButtonStyle,
                text: primaryButtonText!,
                onPressed: onPrimaryPressed,
              ),
              FusionAppButton(
                width: 438,
                style: secondaryButtonStyle,
                text: secondaryButtonText!,
                onPressed: onSecondaryPressed,
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Static methods to show different dialog types
  static Future<void> showSuccess(
    BuildContext context, {
    DialogType type = DialogType.success,
    String title = '',
    required String description,
    String? copyText,
    String? contactEmail,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool showCopyButton = false,
    bool horizontal = false,
    bool vertical = false,
    FusionAppButtonStyle primaryButtonStyle = FusionAppButtonStyle.primary,
    FusionAppButtonStyle secondaryButtonStyle = FusionAppButtonStyle.secondary,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DialogBox(
        type: DialogType.success,
        title: title,
        description: description,
        copyText: copyText,
        contactEmail: contactEmail,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        showCopyButton: showCopyButton,
        horizontal: horizontal,
        vertical: vertical,
        primaryButtonStyle: primaryButtonStyle,
        secondaryButtonStyle: secondaryButtonStyle,
      ),
    );
  }

  static Future<void> showFailure(
    BuildContext context, {
    required String title,
    required String description,
    String? copyText,
    String? contactEmail,
    String primaryButtonText = 'Try Again',
    String? secondaryButtonText = 'Cancel',
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool showCopyButton = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DialogBox(
        type: DialogType.failure,
        title: title,
        description: description,
        copyText: copyText,
        contactEmail: contactEmail,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        showCopyButton: showCopyButton,
      ),
    );
  }

  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    required String description,
    String? copyText,
    String? contactEmail,
    String primaryButtonText = 'Continue',
    String? secondaryButtonText = 'Cancel',
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool showCopyButton = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DialogBox(
        type: DialogType.warning,
        title: title,
        description: description,
        copyText: copyText,
        contactEmail: contactEmail,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        showCopyButton: showCopyButton,
      ),
    );
  }

  static Future<void> showConfirmation(
    BuildContext context, {
    required String title,
    required String description,
    String? copyText,
    String? contactEmail,
    String primaryButtonText = 'Confirm',
    String? secondaryButtonText = 'Cancel',
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool showCopyButton = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DialogBox(
        type: DialogType.confirmation,
        title: title,
        description: description,
        copyText: copyText,
        contactEmail: contactEmail,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        showCopyButton: showCopyButton,
      ),
    );
  }
}
