import 'package:fusion_lib/models/response_callback.dart';

import '../../domain/entity/login_response_entity.dart';
import '../../domain/entity/registration_response_entity.dart';

abstract class AuthDataSource {
  Future<ResponseCallback<LoginResponseEntity>> signInWithEmailAndPassword({required String email, required String password});

  Future<ResponseCallback<RegistrationResponseEntity>> signUpWithEmailAndPassword({required String email, required String password});

  Future<void> signOut();

  Future<ResponseCallback<void>> refreshToken();
}
