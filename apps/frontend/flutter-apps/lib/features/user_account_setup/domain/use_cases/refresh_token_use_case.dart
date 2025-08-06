import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';

import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<ResponseCallback<void>> call() {
    return repository.refreshToken();
  }
}
