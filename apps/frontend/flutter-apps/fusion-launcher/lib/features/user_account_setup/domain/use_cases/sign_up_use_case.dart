import 'package:fusion_lib/models/response_callback.dart';

import '../entity/registration_response_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<ResponseCallback<RegistrationResponseEntity>> call(String email, String password) async {
    // todo: discuss with team if we want to automatically log in the user after registration
    /*final ResponseCallback<RegistrationResponseEntity> responseCallback = await repository.signUpWithEmailAndPassword(email: email, password: password);
    if (responseCallback.success) {
      // call signin use case to log in the user after successful registration
      // This is a common pattern to automatically log in the user after registration
      final ResponseCallback<LoginResponseEntity> logInResponseCallback = await serviceLocator<SignInUseCase>().call(email, password);

      if (logInResponseCallback.success) {
        await serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.userDetails, jsonEncode(logInResponseCallback.data?.toJson()));

        serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.accessToken, logInResponseCallback.data!.accessToken);
        serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.refreshToken, logInResponseCallback.data!.refreshToken);
        serviceLocator<SharedPreferencesHandler>().setString(SharedPreferenceKeys.expiry, logInResponseCallback.data!.expiry.toString());
        serviceLocator<SharedPreferencesHandler>().setBool(SharedPreferenceKeys.isLoggedIn, true);
      }
    }
    return responseCallback;*/

    return repository.signUpWithEmailAndPassword(email: email, password: password);
  }
}
