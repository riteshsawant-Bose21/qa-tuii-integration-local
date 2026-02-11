import 'package:fusion_launcher/features/home/domain/repositories/home_page_repository.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/service_locator.dart';
import '../entities/upload_file_entity.dart';

class UploadFileUseCase {
  final HomePageRepository repository = serviceLocator<HomePageRepository>();

  Future<ResponseCallback<UploadFileEntity>> call({
    required String filename,
    required String filePath,
  }) async {
    final ResponseCallback<UploadFileEntity> responseCallback = await repository.uploadFile(
      filename: filename,
      filePath: filePath,
    );
    if (responseCallback.success) {
      return responseCallback;
    } else {
      return ResponseCallback<UploadFileEntity>(
        success: false,
        message: responseCallback.message,
        data: null,
      );
    }
  }
}
