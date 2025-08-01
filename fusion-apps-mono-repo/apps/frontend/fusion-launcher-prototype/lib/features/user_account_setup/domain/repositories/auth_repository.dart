import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';

import '../entity/login_response_entity.dart';
import '../entity/registration_response_entity.dart';

abstract class AuthRepository {
  Future<ResponseCallback<LoginResponseEntity>> signInWithEmailAndPassword({required String email, required String password});

  Future<ResponseCallback<RegistrationResponseEntity>> signUpWithEmailAndPassword({required String email, required String password});

  Future<void> signOut();

  Future<ResponseCallback<void>> refreshToken();
}
