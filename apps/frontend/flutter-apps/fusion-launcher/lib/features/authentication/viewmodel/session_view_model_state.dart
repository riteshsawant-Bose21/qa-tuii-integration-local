part of 'session_view_model.dart';

@immutable
sealed class SessionViewModelState {}

final class SessionViewModelInitial extends SessionViewModelState {}

final class SessionValid extends SessionViewModelState {}

final class SessionExpired extends SessionViewModelState {}
