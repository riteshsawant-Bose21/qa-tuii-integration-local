import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String confirmText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmText,
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    
    final confirmColor = isDestructive ? context.colorScheme.error : context.colorScheme.primary;

    return AlertDialog(
      backgroundColor: context.colorScheme.elevation2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
    color: context.colorScheme.elevation3, 
    width: 1,
  ),
        
      ),
      
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: context.colorScheme.white,
            // surfaceTintColor: Colors.transparent,
          //  elevation: 0,
          ),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text(confirmText),
        ),
      ],
    );
  }
}
