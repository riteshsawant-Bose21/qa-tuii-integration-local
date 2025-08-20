import 'dart:typed_data';

import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/service_locator.dart';
import '../repositories/home_page_repository.dart';

class FetchFileUsecase {
  final HomePageRepository repository = serviceLocator<HomePageRepository>();

  Future<ResponseCallback<Uint8List>> call({
    required String fileId,
  }) async {
    final ResponseCallback<Uint8List> responseCallback = await repository.fetchFile(
      fileId: fileId,
    );
    if (responseCallback.success) {
      return responseCallback;
    } else {
      return ResponseCallback<Uint8List>(
        success: false,
        message: responseCallback.message,
        data: null,
      );
    }
  }
}
