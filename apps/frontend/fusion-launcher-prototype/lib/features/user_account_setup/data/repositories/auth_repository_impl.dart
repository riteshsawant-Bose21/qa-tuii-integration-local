

import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';
import 'package:fusion_design_tool_prototype/features/user_account_setup/domain/entity/login_response_entity.dart';
import 'package:fusion_design_tool_prototype/features/user_account_setup/domain/entity/registration_response_entity.dart';
import 'package:fusion_design_tool_prototype/features/user_account_setup/domain/repositories/auth_repository.dart';

import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDatasource;

  AuthRepositoryImpl(this._authDatasource);

  @override
  Future<ResponseCallback<LoginResponseEntity>> signInWithEmailAndPassword({required String email, required String password}) {
    return _authDatasource.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<ResponseCallback<RegistrationResponseEntity>> signUpWithEmailAndPassword({required String email, required String password}) {
    return _authDatasource.signUpWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<ResponseCallback<void>> refreshToken() {
    return _authDatasource.refreshToken();
  }

  @override
  Future<void> signOut() {
    return _authDatasource.signOut();
  }
}
