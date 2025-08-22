import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_launcher/core/services/user_profile_manager.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/profile_account_secutity_tab.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/profile_contact_location_tab.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/profile_preferences_tab.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/service_locator.dart';
import '../../../../core/utils/fusion_utils.dart';

class ProfileTabContent extends StatefulWidget {
  const ProfileTabContent({super.key});

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserProfileManager userProfileManager = serviceLocator<UserProfileManager>();
  final SharedPreferencesHandler prefs = serviceLocator<SharedPreferencesHandler>();

  /// Account & Security controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Contact & Location controllers
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _timezoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    autoFillProfileData();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message),
      ),
    );
  }

  /// Auto-fill profile data from userProfileManager.value
  Future<void> autoFillProfileData() async {
    _fullNameController.text = userProfileManager.value.personalInfo.name;
    _companyController.text = userProfileManager.value.personalInfo.organization;
    _jobTitleController.text = userProfileManager.value.personalInfo.jobTitle;
    _emailController.text = userProfileManager.value.security.username;
    _phoneController.text = userProfileManager.value.personalInfo.phone;

    _usernameController.text = userProfileManager.value.security.username;
    _passwordController.text = userProfileManager.value.security.password;

    _addressLine1Controller.text = userProfileManager.value.address.addressLine1;
    _addressLine2Controller.text = userProfileManager.value.address.addressLine2;
    _cityController.text = userProfileManager.value.address.city;
    _stateController.text = userProfileManager.value.address.state;
    _zipCodeController.text = userProfileManager.value.address.zipCode;
    _countryController.text = userProfileManager.value.address.country;
    _timezoneController.text = userProfileManager.value.address.timezone;
    _locationController.text = userProfileManager.value.location;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _timezoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Gather data from all tabs and return a UserProfile model.
  /// Account & Contact data come from controllers; Preferences are taken from userProfileManager.
  UserProfile _gatherProfileData() {
    return UserProfile(
      personalInfo: PersonalInfo(
        name: _fullNameController.text,
        organization: _companyController.text,
        jobTitle: _jobTitleController.text,
        phone: _phoneController.text,
      ),
      security: Security(
        username: _usernameController.text,
        password: _passwordController.text,
        isTwoFactorEnabled: userProfileManager.value.security.isTwoFactorEnabled,
        enableEmailNotifications: userProfileManager.value.security.enableEmailNotifications,
        enableSMSNotifications: userProfileManager.value.security.enableSMSNotifications,
      ),
      address: Address(
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipCodeController.text,
        country: _countryController.text,
        timezone: _timezoneController.text,
      ),
      measurementUnit: userProfileManager.value.measurementUnit,
      currency: userProfileManager.value.currency,
      language: userProfileManager.value.language,
      location: _locationController.text,
      notifications: userProfileManager.value.notifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: Colors.black,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              tabs: const <Widget>[
                Tab(text: 'Account & Security'),
                Tab(text: 'Contact & Location'),
                Tab(text: 'Preferences'),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<UserProfile>(
              valueListenable: userProfileManager,
              builder: (BuildContext context, UserProfile profile, _) {
                final Security security = profile.security;
                return TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    /// Account & Security Tab
                    AccountSecurityTab(
                      fullNameController: _fullNameController,
                      companyController: _companyController,
                      jobTitleController: _jobTitleController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      isTwoFactorEnabled: security.isTwoFactorEnabled,
                      enableEmailNotifications: security.enableEmailNotifications,
                      enableSMSNotifications: security.enableSMSNotifications,
                      onTwoFactorChanged: (bool val) {
                        userProfileManager.value = userProfileManager.value.copyWith(
                          security: userProfileManager.value.security.copyWith(isTwoFactorEnabled: val),
                        );
                      },
                      onEmailNotifChanged: (bool val) {
                        userProfileManager.value = userProfileManager.value.copyWith(
                          security: userProfileManager.value.security.copyWith(enableEmailNotifications: val),
                        );
                      },
                      onSMSNotifChanged: (bool val) {
                        userProfileManager.value = userProfileManager.value.copyWith(
                          security: userProfileManager.value.security.copyWith(enableSMSNotifications: val),
                        );
                      },
                    ),

                    /// Contact & Location Tab
                    ContactLocationTab(
                      addressLine1Controller: _addressLine1Controller,
                      addressLine2Controller: _addressLine2Controller,
                      cityController: _cityController,
                      stateController: _stateController,
                      zipCodeController: _zipCodeController,
                      countryController: _countryController,
                      timezoneController: _timezoneController,
                    ),

                    /// Preferences Tab
                    PreferencesTab(
                      measurementUnit: profile.measurementUnit,
                      currency: profile.currency,
                      language: profile.language,
                      locationController: _locationController,
                      productUpdates: profile.notifications.productUpdates,
                      projectActivity: profile.notifications.projectActivity,
                      trainingResources: profile.notifications.trainingAndResources,
                      onMeasurementUnitChanged: (String val) {
                        userProfileManager.value = userProfileManager.value.copyWith(measurementUnit: val);
                      },
                      onCurrencyChanged: (String val) {
                        userProfileManager.value = userProfileManager.value.copyWith(currency: val);
                      },
                      onLanguageChanged: (String val) {
                        userProfileManager.value = userProfileManager.value.copyWith(language: val);
                      },
                      onLocationChanged: (String val) {
                        userProfileManager.value = userProfileManager.value.copyWith(location: val);
                      },
                      onProductUpdatesChanged: (bool val) {
                        userProfileManager.value = userProfileManager.value.copyWith(
                          notifications: userProfileManager.value.notifications.copyWith(productUpdates: val),
                        );
                      },
                      onProjectActivityChanged: (bool val) {
                        userProfileManager.value = userProfileManager.value.copyWith(
                          notifications: userProfileManager.value.notifications.copyWith(projectActivity: val),
                        );
                      },
                      onTrainingResourcesChanged: (bool val) {
                        userProfileManager.value = userProfileManager.value.copyWith(
                          notifications: userProfileManager.value.notifications.copyWith(trainingAndResources: val),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Pass onSave callback to action buttons.
          ProfileActionButtons(
            onSave: () async {
              try {
                final UserProfile newProfile = _gatherProfileData();
                final bool isAdmin = prefs.getBool(SharedPreferenceKeys.adminLogin) ?? false;
                if (isAdmin) {
                  userProfileManager.value = newProfile;
                } else {
                  FusionUtils.showLoader(context);
                  final ResponseCallback<void> response = await userProfileManager.saveUserProfile(newProfile);

                  if (context.mounted) {
                    FusionUtils.hideLoader(context);
                  } // Always hide loader before UI feedback

                  if (response.success) {
                    userProfileManager.value = newProfile;
                    autoFillProfileData();
                    _showSnackBar('Profile saved successfully!', Colors.green);
                    print("Profile saved successfully.");
                  } else {
                    _showSnackBar('Failed to save profile: ${response.message}', Colors.red);
                    print("Failed to save profile: ${response.message}");
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  FusionUtils.hideLoader(context);
                }
                _showSnackBar('Something went wrong. Please try again.', Colors.red);
                print("Exception during profile save: $e");
              }
            },
          ),
        ],
      ),
    );
  }
}

class ProfileActionButtons extends StatelessWidget {
  final Future<void> Function()? onSave;

  const ProfileActionButtons({super.key, this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: <Widget>[
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
