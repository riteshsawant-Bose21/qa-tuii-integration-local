import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/pava/pava_message_model.dart';

class MessageSyncService {
  final FusionNetworkClient networkClient;

  MessageSyncService({required this.networkClient});

  /// GET /pava/messages — list all audio messages on the fusion server
  Future<ResponseCallback<List<PavaMessageModel>>> getMessages({required String vip}) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.get(
        api: FusionApiEndpoint.pavaMessages,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        if (response.data == null) {
          return ResponseCallback<List<PavaMessageModel>>.success(<PavaMessageModel>[]);
        }

        // Decode if response.data is a raw JSON string.
        final dynamic decoded = response.data is String ? jsonDecode(response.data as String) : response.data;

        // Server may return:
        //  - null
        //  - an empty map {} when there are no messages
        //  - a map of the form { "messages": [ ... ] } when there are messages
        //  - (legacy) a bare list [ ... ]
        List<dynamic> list;
        if (decoded == null) {
          list = <dynamic>[];
        } else if (decoded is Map<String, dynamic>) {
          final dynamic raw = decoded['messages'];
          list = raw is List<dynamic> ? raw : <dynamic>[];
        } else if (decoded is List<dynamic>) {
          list = decoded;
        } else {
          list = <dynamic>[];
        }

        final List<PavaMessageModel> messages = list.map((dynamic e) => PavaMessageModel.fromJson(e as Map<String, dynamic>)).toList();
        return ResponseCallback<List<PavaMessageModel>>.success(messages);
      } else {
        return ResponseCallback<List<PavaMessageModel>>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<List<PavaMessageModel>>.failure(e.toString());
    }
  }

  /// POST /pava/messages — upload a single audio file (multipart)
  Future<ResponseCallback<PavaMessageModel>> uploadMessage({
    required String vip,
    required File audioFile,
    required String displayName,
  }) async {
    try {
      final FormData formData = FormData.fromMap(<String, dynamic>{
        'binary': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'display_name': displayName,
      });

      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.pavaMessages,
        data: formData,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success && response.data != null) {
        final PavaMessageModel uploaded = PavaMessageModel.fromJson(response.data as Map<String, dynamic>);
        return ResponseCallback<PavaMessageModel>.success(uploaded);
      } else {
        return ResponseCallback<PavaMessageModel>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<PavaMessageModel>.failure(e.toString());
    }
  }

  /// PUT /pava/messages/:id/trigger — trigger playback of a message by its server-assigned id
  Future<ResponseCallback<bool>> triggerMessage({
    required String vip,
    required String triggerId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.put(
        api: FusionApiEndpoint.pavaMessages,
        additionalPath: '$triggerId/trigger',
        baseUrlToOverride: vip,
        isSecure: false,
        data: {
          "zones": ["all"],
          "priority": 100,
        },
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }
}
