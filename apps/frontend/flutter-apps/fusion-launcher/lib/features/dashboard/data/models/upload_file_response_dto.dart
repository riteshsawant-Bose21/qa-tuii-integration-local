import '../../domain/entities/upload_file_entity.dart';

class UploadFileResponseDto {
  final String fileId;

  UploadFileResponseDto({required this.fileId});

  factory UploadFileResponseDto.fromJson(Map<String, dynamic> json) {
    return UploadFileResponseDto(
      fileId: json['fileId'] as String,
    );
  }

  UploadFileEntity toEntity() {
    return UploadFileEntity(fileId: fileId);
  }

  factory UploadFileResponseDto.fromEntity(UploadFileEntity entity) {
    return UploadFileResponseDto(fileId: entity.fileId);
  }
}
