import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/aes67/configation_aes67.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

/// Small filled circle indicating active/inactive status
class StatusDot extends StatelessWidget {
  final bool active;
  const StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.aes67_status_dot),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? context.colorScheme.primaryColor : context.colorScheme.textSecondary,
        ),
      ),
    );
  }
}
