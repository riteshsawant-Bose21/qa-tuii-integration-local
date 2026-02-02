import 'package:fusion_lib/models/response_callback.dart';

import '../../../../core/service_locator.dart';
import '../repositories/home_page_repository.dart';

class DeleteProjectUseCase {
  final HomePageRepository repository = serviceLocator<HomePageRepository>();

  Future<ResponseCallback<void>> call({required String projectId}) async {
    final ResponseCallback<void> responseCallback = await repository.deleteProject(projectId: projectId);
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
