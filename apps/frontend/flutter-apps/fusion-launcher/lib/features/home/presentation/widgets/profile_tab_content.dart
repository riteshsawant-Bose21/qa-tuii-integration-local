import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../../../core/service_locator.dart';
import 'profile_sections/profile_account_secutity_section.dart';
import 'profile_sections/profile_contact_location_section.dart';
import 'profile_sections/profile_information_section.dart';
import 'profile_sections/profile_preferences_section.dart';

enum ProfileTabSections {
  personalInformation("Personal Information"),
  accountCredentials("Account Credentials"),
  contactAndLocation("Contact & Location"),
  preferences("Preferences");

  const ProfileTabSections(this.title);
  final String title;
}

class ProfileTabContent extends StatefulWidget {
  const ProfileTabContent({super.key});

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent> with SingleTickerProviderStateMixin {
  ProfileTabSections _currentProfileSideTab = ProfileTabSections.personalInformation;
  final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();

  @override
  Widget build(BuildContext context) {
    final Color surfaceThemeColor = context.colorScheme.onSurface;

    return ValueListenableBuilder<UserProfile>(
      valueListenable: userProfileManager,
      builder: (BuildContext context, UserProfile value, Widget? child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16.0),

                child: Column(
                  children: <Widget>[
                    ...ProfileTabSections.values.map(
                      (ProfileTabSections tab) {
                        final bool isSelected = tab == _currentProfileSideTab;

                        return InkWell(
                          onTap: () => setState(() => _currentProfileSideTab = tab),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? surfaceThemeColor.withValues(alpha: 0.04) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              spacing: 16,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    tab.title,
                                    style: context.textTheme.labelMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ==================================
              //   Right Section - Tab Content
              // ==================================
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Builder(
                    builder: (BuildContext context) {
                      if (_currentProfileSideTab == ProfileTabSections.personalInformation) {
                        return const ProfileInformationTab();
                      } else if (_currentProfileSideTab == ProfileTabSections.accountCredentials) {
                        return const AccountCredentialsTab();
                      } else if (_currentProfileSideTab == ProfileTabSections.contactAndLocation) {
                        return const ProfileContactAndLocationTab();
                      } else if (_currentProfileSideTab == ProfileTabSections.preferences) {
                        return const ProfilePreferencesTab();
                      } else {
                        throw UnimplementedError("No widget implemented for the selected tab.");
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
