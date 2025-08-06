import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';

import '../../../../core/service_locator.dart';
import '../repositories/home_page_repository.dart';

class UpdateProjectUsecase {
  final HomePageRepository repository = serviceLocator<HomePageRepository>();

  Future<ResponseCallback<void>> call({
    required String name,
    required String description,
    required String metadata,
    required String id,
  }) async {
    final ResponseCallback<void> responseCallback = await repository.updateProject(
      name: name,
      description: description,
      metadata: metadata,
      id: id,
    );
    if (responseCallback.success) {
      return responseCallback;
    } else {
      return ResponseCallback<void>(
        success: false,
        message: responseCallback.message,
        data: null,
      );
    }
  }
}
