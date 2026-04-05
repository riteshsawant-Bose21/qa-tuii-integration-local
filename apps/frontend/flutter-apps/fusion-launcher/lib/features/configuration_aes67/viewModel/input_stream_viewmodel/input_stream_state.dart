part of 'input_stream_viewmodel.dart';

sealed class InputStreamState {
  const InputStreamState();
}

class InputStreamInitial extends InputStreamState {
  const InputStreamInitial();
}

class InputStreamLoading extends InputStreamState {
  const InputStreamLoading();
}

class InputStreamLoaded extends InputStreamState {
  final Aes67Config stream;
  final bool isSessionSectionExpanded;

  const InputStreamLoaded({
    required this.stream,
    this.isSessionSectionExpanded = false,
  });

  InputStreamLoaded copyWith({
    Aes67Config? stream,
    bool? isSessionSectionExpanded,
  }) {
    return InputStreamLoaded(
      stream: stream ?? this.stream,
      isSessionSectionExpanded: isSessionSectionExpanded ?? this.isSessionSectionExpanded,
    );
  }
}

class InputStreamError extends InputStreamState {
  final String message;
  const InputStreamError({required this.message});
}
