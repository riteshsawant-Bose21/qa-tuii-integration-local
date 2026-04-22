import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:fusion_app/core/utils/qr_data_parser.dart';
import 'package:fusion_app/features/scanner/view_model/fusion_qr_service.dart';
import 'package:fusion_lib/fusion_lib.dart';

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

  final List<WallZone> _zones = [];

  List<WallZone> get getZones =>_zones;
  String vipAddress = "";
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
        vipAddress = uri.queryParameters['vip']!;
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
    try{
     WebSocketService().connect('ws://${details.vip}:8080/ws');


        emit(QrConnecting());
        ResponseCallback<WallControllerConfig> model = await _qrService.getSchema(details.vip);
        print("Connection response: success=${model.success}, message=${model.message}");
        if(model.success) {
          FusionLogger.log(
            tag: LogTag.debug,
            message: 'Schema retrieved: ${model.data!.toJson()}',
          );

          final List<String> zoneIds = [];

          WallControllerConfig schemaModel = model.data!;
          WallController? controller = schemaModel.controllers
              .firstWhereOrNull((ctrl) => ctrl.id == details.configId);

          if(controller == null){ //dead code itseems
            print("No Controllers Found");
            emit(QrError("Invalid QR Code"));
          }

            zoneIds.addAll(controller?.zoneIds ?? []);


          for (WallZone item in schemaModel.zones ?? []) {
            WallZone? zone;
            for (var id in zoneIds) {
              if (id == item.id) {
                 zone = WallZone(
                   functionId: item.functionId,
                    id: id,
                    name: item.name,
                    subZones: [],
                    sources: item.sources ?? [],
                   gain: item.gain,
                   ono: item.ono ,
                );
              }
            }

          if(item.subZones.isNotEmpty) {
            print("Subzones found, adding sources directly to parent zone : ${item.subZones.length}");

            for(var subZone in item.subZones) {
              zone!.subZones.add(WallSubZone(
                  id: subZone.id,
                  name: subZone.name,
                  gain: subZone.gain,
                ono: subZone.ono,
              ));
            }
            _zones.add(zone!);
          }else{
            print("Subzones empty, adding sources directly to parent zone : ${item.subZones.length}");

            zone!.subZones.add(WallSubZone(
              id: item.id,
              name: item.name,
              gain: item.gain,
              ono: WallSubZoneOno.fromJson({
                'subZone': 0,
                'gain': 0,
                'mute': 0,
              }) ,
            ));
            _zones.add(zone);
          }

            // for (var id in zoneIds) {
            //   if (id == item.id) {
            //     zones.add(
            //         ZoneModel(id: id,
            //             name: item.name!,
            //             sources:
            //             item.sources!.map((src) =>
            //                 ZoneSourceModel(
            //                     id: src.sourceId!,
            //                     name: src.sourceName!,
            //                     gainID: item.gain!.gainID ?? "",
            //                     icon: Icons.yard_outlined,
            //                     volume: AudioUtils.toUiVolume(0)
            //                 )).toList()
            //         ));
            //   }
            // }
            //
            // for (Zones item in item.subZones) {
            //
            // }
          print("Zones added: ${_zones.length}");

          emit(QrConnected(schemaModel));
        }
        }else{
         // print("Server ERROR: ${model.message}");
          emit(QrError('Server ERROR'));
        }



    } catch (e) {

      FusionLogger.log(
        tag: LogTag.exceptions,
        message: 'Connection error: $e',
      );

      emit(QrError("Connection failed"));
    }
  }

  // Future<void> local(raw) async {
  //   final uri = Uri.tryParse(raw);
  //   print("Parsed URI: $uri");
  //
  //   if (uri != null && uri.queryParameters.isNotEmpty) {
  //     Map<String,dynamic> details = {
  //       "vip": uri.queryParameters['vip'],
  //       "controller_id": uri.queryParameters['controller_id'],
  //     };
  //
  //   print("Attempting connection with VIP: ${details['vip']}, Controller ID: ${details['controller_id']}");
  //
  //   emit(QrConnecting());
  //  // ResponseCallback<SchemaModel> model = await _qrService.getSchema();
  //
  //   if(true) {
  //     FusionLogger.log(
  //       tag: LogTag.debug,
  //       message: 'Schema retrieved:',
  //     );
  //     final List<String> zoneIds = [];
  //
  //     // SchemaModel schemaModel = model.data!;
  //     SchemaModel schemaModel = SchemaModel.fromJson(schemeData);
  //     print("schemaModel");
  //     print(schemaModel.wallControllerConfig==null);
  //     print(schemaModel.wallControllerConfig!.toJson());
  //     Controllers? controller = schemaModel.wallControllerConfig!
  //         .controllers?.firstWhere((ctrl) => ctrl.id == details['controller_id']);
  //     print("controller");
  //     print(controller!.toJson());
  //     if (controller != null) {
  //       zoneIds.addAll(controller.zoneIds ?? []);
  //     }
  //     print("zoneIds");
  //     print(zoneIds);
  //     List<ZoneModel> zones = [];
  //     for (Zones item in schemaModel.wallControllerConfig?.zones ?? []) {
  //       for (var id in zoneIds) {
  //         if (id == item.id) {
  //           zones.add(ZoneModel(id: id, name: item.name!,
  //               gainID:item.gain!.gainID ?? "",
  //               sources:
  //               item.sources!.map((src) =>
  //                   ZoneSourceModel(
  //                       id: src.sourceId!,
  //                       name: src.sourceName!,
  //                       icon: Icons.yard_outlined,
  //                       volume: double.parse(
  //                           item.gain?.defaultGainValue ?? "0")
  //                   )).toList()
  //           ));
  //         }
  //       }
  //     }
  //     _zones.addAll(zones);
  //
  //     emit(QrConnected(schemaModel));
  //   }else{
  //
  //     emit(QrInitial());
  //   }
  //   }
  //
  // }

  /// Reset state
  void reset() {
    emit(QrInitial());
  }
}