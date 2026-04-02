import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_app/core/utils/qr_data_parser.dart';
import 'package:fusion_app/features/scanner/view_model/fusion_qr_service.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/models/schema_data.dart' show schemeData;

part 'qr_scanner_view_model_state.dart';

class QrScannerViewModel extends Cubit<QrScannerState> {

  final FusionQRService _qrService;
  final FusionNetworkClient _networkClient;

  QrScannerViewModel({
    required FusionQRService qrService,
    required FusionNetworkClient networkClient,
  }) : _qrService = qrService,
        _networkClient = networkClient,
        super(QrInitial());

  final List<ZoneModel> _zones = [];

  List<ZoneModel> get getZones =>_zones;

  /// Emit scanning
  void startScanning() {
    emit(QrScanning());
  }

  /// Handle scanned QR
  void onQrScanned(String rawData) {
    try {
      emit(QrScanning());

      final parsed = _parseQr(rawData);

      emit(QrParsed(
        vip: parsed['vip'],
        controllerId: parsed['controller_id'],
      ));

      _connect(QRConnectionDetails(vip: parsed['vip'],configId:  parsed['controller_id']));
    } catch (e) {
      FusionLogger.log(
        tag: LogTag.exceptions,
        message: 'QR parse error: $e',
      );

      emit(QrError("Invalid QR code"));
    }
  }

  /// Parse QR (supports JSON + URI)
  Map<String, dynamic> _parseQr(String raw) {
    print( "Raw QR data: $raw");
    try {
      // 👉 Try JSON first
      return jsonDecode(raw);
    } catch (_) {
      // 👉 Try URI format
      final uri = Uri.tryParse(raw);
      print("Parsed URI: $uri");

      if (uri != null && uri.queryParameters.isNotEmpty) {
        return {
          "vip": uri.queryParameters['vip'],
          "controller_id": uri.queryParameters['controller_id'],
        };
      }

      throw Exception("Invalid QR format");
    }
  }

  /// Connect to device/server
  Future<void> _connect(QRConnectionDetails details) async {
    print("Attempting connection with VIP: ${details.vip}, Controller ID: ${details.configId}");

      emit(QrConnecting());
        ResponseCallback<SchemaModel> model = await _qrService.getSchema();

        if(model.success) {
          FusionLogger.log(
            tag: LogTag.debug,
            message: 'Schema retrieved: ${model.data!}',
          );
          final List<String> zoneIds = [];

          SchemaModel schemaModel = model.data!;
         // SchemaModel schemaModel = SchemaModel.fromJson(schemeData);
          print("schemaModel");
          print(schemaModel.wallControllerConfig==null);
          print(schemaModel.wallControllerConfig!.toJson());
          Controllers? controller = schemaModel.wallControllerConfig!
              .controllers?.firstWhere((ctrl) => ctrl.id == details.configId);
          print("controller");
          print(controller!.toJson());
          if (controller != null) {
            zoneIds.addAll(controller.zoneIds ?? []);
          }
          print("zoneIds");
          print(zoneIds);
          List<ZoneModel> zones = [];
          for (Zones item in schemaModel.wallControllerConfig?.zones ?? []) {
            for (var id in zoneIds) {
              if (id == item.id) {
                zones.add(ZoneModel(id: id, name: item.name!,
                    gainID:item.gain!.gainID ?? "",
                    sources:
                    item.sources!.map((src) =>
                        ZoneSourceModel(
                            id: src.sourceId!,
                            name: src.sourceName!,
                            icon: Icons.yard_outlined,
                            volume: int.parse(
                                item.gain?.defaultGainValue ?? "0")
                        )).toList()
                ));
              }
            }
          }
          _zones.addAll(zones);

          emit(QrConnected(schemaModel));
        }else{

          emit(QrInitial());
        }


    //
    // } catch (e) {
    //
    //   FusionLogger.log(
    //     tag: LogTag.exceptions,
    //     message: 'Connection error: $e',
    //   );
    //
    //   emit(QrError("Connection failed"));
    // }
  }

  Future<void> local(raw) async {
    final uri = Uri.tryParse(raw);
    print("Parsed URI: $uri");

    if (uri != null && uri.queryParameters.isNotEmpty) {
      Map<String,dynamic> details = {
        "vip": uri.queryParameters['vip'],
        "controller_id": uri.queryParameters['controller_id'],
      };

    print("Attempting connection with VIP: ${details['vip']}, Controller ID: ${details['controller_id']}");

    emit(QrConnecting());
    //ResponseCallback<SchemaModel> model = await _qrService.getSchema();

    if(true) {
      FusionLogger.log(
        tag: LogTag.debug,
        message: 'Schema retrieved:',
      );
      final List<String> zoneIds = [];

      // SchemaModel schemaModel = model.data!;
      SchemaModel schemaModel = SchemaModel.fromJson(schemeData);
      print("schemaModel");
      print(schemaModel.wallControllerConfig==null);
      print(schemaModel.wallControllerConfig!.toJson());
      Controllers? controller = schemaModel.wallControllerConfig!
          .controllers?.firstWhere((ctrl) => ctrl.id == details['controller_id']);
      print("controller");
      print(controller!.toJson());
      if (controller != null) {
        zoneIds.addAll(controller.zoneIds ?? []);
      }
      print("zoneIds");
      print(zoneIds);
      List<ZoneModel> zones = [];
      for (Zones item in schemaModel.wallControllerConfig?.zones ?? []) {
        for (var id in zoneIds) {
          if (id == item.id) {
            zones.add(ZoneModel(id: id, name: item.name!,
                gainID:item.gain!.gainID ?? "",
                sources:
                item.sources!.map((src) =>
                    ZoneSourceModel(
                        id: src.sourceId!,
                        name: src.sourceName!,
                        icon: Icons.yard_outlined,
                        volume: int.parse(
                            item.gain?.defaultGainValue ?? "0")
                    )).toList()
            ));
          }
        }
      }
      _zones.addAll(zones);

      emit(QrConnected(schemaModel));
    }else{

      emit(QrInitial());
    }
    }

  }

  /// Reset state
  void reset() {
    emit(QrInitial());
  }
}