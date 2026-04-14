part of 'auth_view_model.dart';

@immutable
sealed class AuthViewModelState {}

final class AuthViewModelInitial extends AuthViewModelState {}

final class AuthLoading extends AuthViewModelState {}

final class Authenticated extends AuthViewModelState {}

final class Unauthenticated extends AuthViewModelState {}

final class AuthError extends AuthViewModelState {
  final String message;

  AuthError(this.message);
}

final class AuthWebRedirectInProgress extends AuthViewModelState {
  AuthWebRedirectInProgress();
}
