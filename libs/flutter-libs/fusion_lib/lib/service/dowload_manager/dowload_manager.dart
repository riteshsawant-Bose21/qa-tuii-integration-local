import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/service/dowload_manager/file_download.dart';

class TransferManagerState extends Equatable {
  final Map<String, FileTransferCubit> tasks;

  const TransferManagerState({this.tasks = const {}});
  List<FileTransferCubit> get downloads => tasks.values.where((t) => t.type == TransferType.download).toList();
  List<FileTransferCubit> get uploads => tasks.values.where((t) => t.type == TransferType.upload).toList();
  List<FileTransferCubit> get active => tasks.values.where((t) => t.state.status == TransferStatus.inProgress).toList();

  TransferManagerState copyWith({Map<String, FileTransferCubit>? tasks}) => TransferManagerState(tasks: tasks ?? this.tasks);

  @override
  List<Object?> get props => [tasks.keys.toList()];
}

class TransferManagerCubit extends Cubit<TransferManagerState> {
  TransferManagerCubit() : super(const TransferManagerState());

  FileDownloadCubit enqueueDownload({required String downloadUrl, required String savePath, required String id}) {
    final taskId = id;
    if (state.tasks.containsKey(taskId)) {
      return state.tasks[taskId] as FileDownloadCubit;
    }

    final task = FileDownloadCubit(url: downloadUrl, savePath: savePath, id: taskId);
    _addTask(taskId, task);
    return task;
  }

  FileUploadCubit enqueueUpload({
    required String id,
    required String apiUrl,
    required Object data,
    Map<String, String>? headers,
  }) {
    final taskId = id;
    if (state.tasks.containsKey(taskId)) {
      return state.tasks[taskId] as FileUploadCubit;
    }

    final task = FileUploadCubit(
      apiUrl: apiUrl,
      data: data,
      id: taskId,
      headers: headers,
    );
    _addTask(taskId, task);
    return task;
  }

  void _addTask(String id, FileTransferCubit task) {
    emit(state.copyWith(tasks: {...state.tasks, id: task}));
    task.start();
  }

  void cancel(String id) => state.tasks[id]?.cancel();

  void cancelAll() {
    for (final task in state.tasks.values) {
      task.cancel();
    }
  }

  void remove(String id) {
    state.tasks[id]?.close();
    final updated = Map<String, FileTransferCubit>.from(state.tasks)..remove(id);
    emit(state.copyWith(tasks: updated));
  }

  @override
  Future<void> close() {
    for (final task in state.tasks.values) {
      task.close();
    }
    return super.close();
  }
}
