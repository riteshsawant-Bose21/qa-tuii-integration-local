import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class FusionActionPopup extends StatefulWidget {
  final String title;
  final String description;
  final String loadingMessage;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback? onConfirm; // Optional callback for external logic start

  const FusionActionPopup({
    super.key,
    required this.title,
    required this.description,
    required this.loadingMessage,
    this.confirmButtonText = 'Yes',
    this.cancelButtonText = 'No',
    this.onConfirm,
  });

  @override
  State<FusionActionPopup> createState() => _FusionActionPopupState();
}

class _FusionActionPopupState extends State<FusionActionPopup> {
  bool _isLoading = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoading() {
    widget.onConfirm?.call();
    setState(() {
      _isLoading = true;
    });

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colorScheme.elevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FusionAppText(
                    text: widget.title.toUpperCase(),
                    style: context.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Icon(
                        Icons.close,
                        color: context.colorScheme.iconWhite,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // Divider
            Divider(
              thickness: 1,
              color: context.colorScheme.strokeLight,
            ),

            if (_isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Please wait... ",
                              style: context.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.primaryWhite,
                              ),
                            ),
                            TextSpan(
                              text: widget.loadingMessage,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: FusionAppText(
                  text: widget.description,
                  style: context.textTheme.labelMedium,
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: FusionAppText(
                        text: widget.cancelButtonText,
                        style: context.textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _startLoading,
                      child: FusionContainer(
                        raised: true,
                        color: context.colorScheme.elevation1,
                        borderRadius: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.colorScheme.elevation1,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FusionAppText(
                            text: widget.confirmButtonText,
                            style: context.textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
