import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_bloc/flutter_bloc.dart';

enum TransferType { upload, download }

enum TransferStatus { idle, inProgress, completed, failed, cancelled }

class FileTransferState extends Equatable {
  final TransferStatus status;
  final int sent; // upload: bytes sent,    download: bytes received
  final int total; // upload: total bytes,   download: total bytes
  final String? errorMessage;

  const FileTransferState({
    this.status = TransferStatus.idle,
    this.sent = 0,
    this.total = 0,
    this.errorMessage,
  });

  double get progress => (total > 0) ? sent / total : 0.0;

  FileTransferState copyWith({
    TransferStatus? status,
    int? sent,
    int? total,
    String? errorMessage,
  }) => FileTransferState(
    status: status ?? this.status,
    sent: sent ?? this.sent,
    total: total ?? this.total,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, sent, total, errorMessage];
}

class FileDownloadCubit extends FileTransferCubit {
  final String url;
  final String savePath;

  FileDownloadCubit({
    required this.url,
    required this.savePath,
    required super.id,
  }) : super(type: TransferType.download);

  @override
  Future<void> start() => runTransfer(() async {
    await dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (rec, tot) {
        emit(state.copyWith(sent: rec, total: tot));
      },
      options: Options(headers: {'Accept': '*/*'}),
    );
  });
}

class FileUploadCubit extends FileTransferCubit {
  final String apiUrl;
  final Object data;
  final Map<String, String>? headers;

  FileUploadCubit({
    required this.apiUrl,
    required this.data,
    this.headers,
    required super.id,
  }) : super(type: TransferType.upload);

  @override
  Future<void> start() => runTransfer(() async {
    // final file = File(filePath);
    // final fileSize = await file.length();

    await dio.post(
      apiUrl,
      data: data,
      cancelToken: cancelToken,
      onSendProgress: (sent, tot) => emit(state.copyWith(sent: sent, total: tot)),
      options: Options(
        headers: headers,
      ),
    );
  });
}

abstract class FileTransferCubit extends Cubit<FileTransferState> {
  final String id;
  final TransferType type;

  final CancelToken cancelToken = CancelToken();
  final Dio dio = Dio();

  FileTransferCubit({
    required this.id,
    required this.type,
  }) : super(const FileTransferState());

  /// Each subclass implements its own transfer logic
  Future<void> start();

  void cancel() => cancelToken.cancel('User cancelled');

  @protected
  Future<void> runTransfer(Future<void> Function() transfer) async {
    emit(state.copyWith(status: TransferStatus.inProgress));
    try {
      await transfer();
      emit(state.copyWith(status: TransferStatus.completed));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        emit(state.copyWith(status: TransferStatus.cancelled));
      } else {
        emit(state.copyWith(status: TransferStatus.failed, errorMessage: e.message));
      }
    } catch (e) {
      emit(state.copyWith(status: TransferStatus.failed, errorMessage: e.toString()));
    } finally {
      dio.close();
    }
  }

  @override
  Future<void> close() {
    dio.close(force: true);
    return super.close();
  }
}
