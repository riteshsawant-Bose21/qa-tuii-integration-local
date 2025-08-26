import 'package:fusion_launcher/features/dashboard/data/models/user_profile_dto.dart';

class ProfileResponseDto {
  final UserProfileDto userProfileDto;

  ProfileResponseDto({
    required this.userProfileDto,
  });

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return ProfileResponseDto(
      userProfileDto: UserProfileDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
