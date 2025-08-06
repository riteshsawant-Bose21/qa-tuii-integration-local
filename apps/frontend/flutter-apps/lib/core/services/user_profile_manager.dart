import 'package:flutter/cupertino.dart';
import 'package:fusion_design_tool_prototype/core/models/user_profile_model.dart';
import 'package:fusion_design_tool_prototype/features/dashboard/data/models/user_profile_dto.dart';

import '../../features/dashboard/data/models/profile_response_dto.dart';
import '../models/response_callback.dart';
import '../network_clients/fusion_network_client.dart';
import '../service_locator.dart';

class UserProfileManager extends ValueNotifier<UserProfile> {
  UserProfileManager(super.initialProfile);

  /// Updates the user profile with the provided [newProfile].
  Future<ResponseCallback<void>> saveUserProfile(UserProfile newProfile) async {
    try {
      print('Saving user profile: ${newProfile.toJson()}');
      final ResponseCallback<void> responseCallback = await serviceLocator<FusionNetworkClient>().post(
        api: FusionApiEndpoint.saveProfile,
        data: newProfile.toJson(),
      );

      if (responseCallback.success) {
        return ResponseCallback<void>(
          success: true,
          message: responseCallback.message,
        );
      } else {
        print('Failed to save profile: ${responseCallback.message}');
        throw Exception('Failed to save profile: ${responseCallback.message}');
      }
    } catch (e) {
      print('Failed to save profile: $e');
      return ResponseCallback<void>(
        success: false,
        message: 'Failed to save profile: $e',
      );
    }
  }

  /// Retrieves the user profile.
  Future<void> getUserProfile() async {
    try {
      final ResponseCallback<ProfileResponseDto> response = await serviceLocator<FusionNetworkClient>().get(
        api: FusionApiEndpoint.getProfile,
        fromJson: ProfileResponseDto.fromJson,
      );

      if (response.success && response.data != null) {
        final UserProfileDto userProfileDto = response.data!.userProfileDto;
        final Map<String, dynamic> metaData = userProfileDto.metadata;

        value = UserProfile.fromJson(metaData);
        print('User profile retrieved successfully: ${value.toJson()}');
      } else if (response.success && response.data == null) {
        print('No user profile data found.');
      } else {
        print('Failed to retrieve profile: ${response.message}');
        // Handle the error case
        throw Exception('Failed to retrieve profile: ${response.message}');
      }
    } catch (e) {
      print('Error retrieving profile: $e');
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
    print('User profile cleared.');
  }
}
