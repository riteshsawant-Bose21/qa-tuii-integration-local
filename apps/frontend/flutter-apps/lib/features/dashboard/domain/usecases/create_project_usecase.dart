import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';

import '../../../../core/service_locator.dart';
import '../entities/create_project_entity.dart';
import '../repositories/home_page_repository.dart';

class CreateProjectUseCase {
  final HomePageRepository repository = serviceLocator<HomePageRepository>();

  Future<ResponseCallback<CreateProjectEntity>> call({
    required String name,
    required String description,
    required String metadata,
  }) async {
    final ResponseCallback<CreateProjectEntity> responseCallback = await repository.createProject(
      name: name,
      description: description,
      metadata: metadata,
    );
    if (responseCallback.success) {
      return responseCallback;
    } else {
      return ResponseCallback<CreateProjectEntity>(
        success: false,
        message: responseCallback.message,
        data: null,
      );
    }
  }
}
