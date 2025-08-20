import 'package:fusion_lib/models/response_callback.dart';

import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<ResponseCallback<void>> call() {
    return repository.refreshToken();
  }
}
