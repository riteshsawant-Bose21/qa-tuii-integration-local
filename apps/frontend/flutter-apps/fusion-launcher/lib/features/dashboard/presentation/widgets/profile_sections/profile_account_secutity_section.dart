import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/profile_tab_content.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/saved_projects_tab.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../../core/service_locator.dart';

class AccountCredentialsTab extends StatelessWidget {
  const AccountCredentialsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();

    return ValueListenableBuilder<UserProfile>(
      valueListenable: userProfileManager,
      builder: (BuildContext context, UserProfile userProfile, Widget? child) {
        final Security security = userProfile.security;

        return Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FusionAppText(
              text: ProfileTabSections.accountCredentials.title,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.surfaceDim,
              ),
            ),
            const SizedBox(height: 10),
            BorderedTextfield(
              initialValue: security.username,
              label: "User Name",
              hintText: "e.g. John",
              // isEnabled: false,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 10,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: BorderedTextfield(
                    initialValue: security.password,
                    label: "Password",
                    hintText: "Password",
                    // isEnabled: false,
                    isObscured: true,
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // TODO: Implement password reset
                    },
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Colors.transparent,
                    child: Ink(
                      width: 250,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceDim.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: FusionAppText(
                          text: "Change Password",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            BorderedTextfield(
              initialValue: security.username,
              label: "Email",
              hintText: "e.g. john.doe@example.com",
              isEnabled: false,
            ),
            const SizedBox(height: 10),

            TinySwitchWithTitle(
              title: 'Enable Two-Factor Authentication',
              value: userProfile.security.isTwoFactorEnabled,
              onChanged: (bool value) {
                userProfileManager.value = userProfileManager.value.copyWith(
                  security: userProfileManager.value.security.copyWith(
                    isTwoFactorEnabled: value,
                  ),
                );
              },
            ),
            TinySwitchWithTitle(
              title: 'Enable Email Notifications & Updates',
              value: userProfileManager.value.security.enableEmailNotifications,
              onChanged: (bool value) {
                userProfileManager.value = userProfileManager.value.copyWith(
                  security: userProfileManager.value.security.copyWith(
                    enableEmailNotifications: value,
                  ),
                );
              },
            ),
            TinySwitchWithTitle(
              title: 'Enable Text Notifications & Updates',
              value: userProfileManager.value.security.enableSMSNotifications,
              onChanged: (bool value) {
                userProfileManager.value = userProfileManager.value.copyWith(
                  security: userProfileManager.value.security.copyWith(
                    enableSMSNotifications: value,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class TinySwitchWithTitle extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const TinySwitchWithTitle({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          height: 18,
          width: 30,
          child: FittedBox(
            fit: BoxFit.cover,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: context.colorScheme.primary,
              inactiveTrackColor: context.colorScheme.surfaceBright,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashRadius: 0,
              trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) => Colors.transparent),
              thumbColor: WidgetStatePropertyAll<Color>(context.colorScheme.onSurface),
            ),
          ),
        ),

        const SizedBox(width: 8),
        Expanded(
          child: FusionAppText(
            text: title,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.surfaceDim,
            ),
          ),
        ),
      ],
    );
  }
}
