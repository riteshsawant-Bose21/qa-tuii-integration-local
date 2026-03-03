// import 'package:flutter/foundation.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// // Base state classes for ViewModels
// abstract class BaseState {}

// class InitialState extends BaseState {}

// class LoadingState extends BaseState {}

// class LoadedState<T> extends BaseState {
//   final T data;
//   LoadedState(this.data);
// }

// class ErrorState extends BaseState {
//   final String message;
//   ErrorState(this.message);
// }

// // Base ViewModel class with common functionality
// abstract class BaseViewModel<T> extends Cubit<BaseState> {

//   void setState(BaseState newState) {
//     _state = newState;
//     notifyListeners();
//   }

//   void setLoading() => setState(LoadingState());

//   void setLoaded<T>(List<T> data) => setState(LoadedState<List<T>>(data));

//   void setError(String message) => setState(ErrorState(message));

//   bool get isLoading => _state is LoadingState;
//   bool get hasError => _state is ErrorState;
//   bool get isInitial => _state is InitialState;
// }

import 'package:flutter_bloc/flutter_bloc.dart';

// Base state classes for ViewModels
abstract class BaseState<T> {}

class InitialState<T> extends BaseState<T> {}

class LoadingState<T> extends BaseState<T> {}

class LoadedState<T> extends BaseState<T> {
  final T data;
  LoadedState(this.data);
}

class ErrorState<T> extends BaseState<T> {
  final String message;
  ErrorState(this.message);
}

class SuccessState<T> extends BaseState<T> {}

// Base ViewModel class with common functionality
abstract class BaseViewModel<T> extends Cubit<BaseState<T>> {
  BaseViewModel() : super(InitialState<T>());

  void setState(BaseState<T> newState) {
    emit(newState);
  }

  void setLoading() => setState(LoadingState<T>());
  void setLoaded(T data) => setState(LoadedState<T>(data));

  void setError(String message) => setState(ErrorState<T>(message));

  bool get isLoading => state is LoadingState<T>;
  bool get hasError => state is ErrorState<T>;
  bool get isInitial => state is InitialState<T>;
}
