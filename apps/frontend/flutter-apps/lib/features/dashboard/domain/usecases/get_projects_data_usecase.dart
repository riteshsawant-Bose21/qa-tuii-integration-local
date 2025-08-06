import 'package:fusion_design_tool_prototype/features/dashboard/domain/entities/get_projects_entity.dart';

import '../../../../core/models/response_callback.dart';
import '../../../../core/service_locator.dart';
import '../repositories/home_page_repository.dart';

class GetProjectsDataUseCase {
  final HomePageRepository repository = serviceLocator<HomePageRepository>();

  Future<ResponseCallback<List<GetProjectsEntity>>> call() async {
    final ResponseCallback<List<GetProjectsEntity>> responseCallback = await repository.getProjectsData();
    // if (responseCallback.success) {
    return responseCallback;
    // } else {
    //   return ResponseCallback<List<GetProjectsEntity>>(
    //     success: false,
    //     message: responseCallback.message,
    //     data: null,
    //   );
    // }
  }
}
