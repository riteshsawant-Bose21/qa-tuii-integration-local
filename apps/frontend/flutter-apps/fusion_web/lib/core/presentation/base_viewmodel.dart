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
