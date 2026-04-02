import 'package:flutter/cupertino.dart';
import 'package:fusion_launcher/core/models/user_profile_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

class UserProfileManager extends ValueNotifier<UserProfile> {
  UserProfileManager(super.initialProfile);

  /// Updates the user profile with the provided [newProfile].
  // Future<ResponseCallback<void>> saveUserProfile(UserProfile newProfile) async {
  //   try {
  //     debugPrint('Saving user profile: ${newProfile.toJson()}');
  //     final ResponseCallback<void> responseCallback = await serviceLocator<FusionNetworkClient>().post(
  //       api: FusionApiEndpoint.saveProfile,
  //       data: newProfile.toJson(),
  //     );
  //
  //     if (responseCallback.success) {
  //       return ResponseCallback<void>(
  //         success: true,
  //         message: responseCallback.message,
  //       );
  //     } else {
  //       debugPrint('Failed to save profile: ${responseCallback.message}');
  //       throw Exception('Failed to save profile: ${responseCallback.message}');
  //     }
  //   } catch (e) {
  //     debugPrint('Failed to save profile: $e');
  //     return ResponseCallback<void>(
  //       success: false,
  //       message: 'Failed to save profile: $e',
  //     );
  //   }
  // }

  /// Retrieves the user profile.
  Future<void> getUserProfile() async {
    try {
      // final ResponseCallback<ProfileResponseDto> response = await serviceLocator<FusionNetworkClient>().get(
      //   api: FusionApiEndpoint.getProfile,
      //   fromJson: ProfileResponseDto.fromJson,
      // );
      //
      // if (response.success && response.data != null) {
      //   final UserProfileDto userProfileDto = response.data!.userProfileDto;
      //   final Map<String, dynamic> metaData = userProfileDto.metadata;
      //
      //   value = UserProfile.fromJson(metaData);
      //   debugPrint('User profile retrieved successfully: ${value.toJson()}');
      // } else if (response.success && response.data == null) {
      //   debugPrint('No user profile data found.');
      // } else {
      //   debugPrint('Failed to retrieve profile: ${response.message}');
      //   // Handle the error case
      //   throw Exception('Failed to retrieve profile: ${response.message}');
      // }
    } catch (e) {
      debugPrint('Error retrieving profile: $e');
    }
  }

  // clearUserProfile
  Future<void> clearUserProfile() async {
    final UserProfile initialUserProfile = UserProfile(
      personalInfo: PersonalInfo(
        name: "",
        organization: "",
        jobTitle: "",
        phone: "",
      ),

      security: Security(
        username: "",
        password: "",
        isTwoFactorEnabled: false,
        enableEmailNotifications: false,
        enableSMSNotifications: false,
      ),
      address: Address(
        addressLine1: "",
        addressLine2: "",
        city: "",
        state: "",
        zipCode: "",
        country: "",
        timezone: "",
      ),
      measurementUnit: "",
      currency: "USD",
      language: "English (US)",
      notifications: Notifications(productUpdates: false, projectActivity: false, trainingAndResources: false),
      location: '',
    );
    value = initialUserProfile;
    debugPrint('User profile cleared.');
  }
}
