import 'package:flutter/foundation.dart';

// Base state classes for ViewModels
abstract class BaseState {}

class InitialState extends BaseState {}

class LoadingState extends BaseState {}

class LoadedState<T> extends BaseState {
  final T data;
  LoadedState(this.data);
}

class ErrorState extends BaseState {
  final String message;
  ErrorState(this.message);
}

// Base ViewModel class with common functionality
abstract class BaseViewModel extends ChangeNotifier {
  BaseState _state = InitialState();

  BaseState get state => _state;

  void setState(BaseState newState) {
    _state = newState;
    notifyListeners();
  }

  void setLoading() => setState(LoadingState());

  void setLoaded<T>(T data) => setState(LoadedState<T>(data));

  void setError(String message) => setState(ErrorState(message));

  bool get isLoading => _state is LoadingState;
  bool get hasError => _state is ErrorState;
  bool get isInitial => _state is InitialState;
}
