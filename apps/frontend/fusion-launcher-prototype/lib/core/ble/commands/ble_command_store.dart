import 'dart:convert';
import 'dart:typed_data';

class BleCommandStore {
  Uint8List getCommand({required Command command, Map<String, dynamic>? param}) {
    switch (command) {
      case Command.setVip:
        return generateFusionBleCommand(param!);
      case Command.checkVip:
        return generateFusionBleCommand(param!);
      case Command.blinkLed:
        throw UnimplementedError("Blink LED command is not implemented yet."); //Not implemented by fusion server side yet
      case Command.getFusionDevices:
        return generateFusionBleCommand(param!);
    }
  }

  Uint8List generateFusionBleCommand(Map<String, dynamic> map) {
    final String method = map["method"] ?? "";
    final String url = map["url"] ?? "";
    final Map<String, dynamic>? body = map["body"] as Map<String, dynamic>?;
    final Map<String, dynamic> requestMap = <String, dynamic>{
      "type": "request",
      "payload": <String, dynamic>{
        "method": method,
        "url": url,
        "body": body ?? <String, dynamic>{},
      },
    };

    final String requestJson = jsonEncode(requestMap);
    final Uint8List requestData = utf8.encode(requestJson);
    return requestData;
  }
}

class CommandParams {
  static const String localHost = "http://localhost:8080";
  static const String method = "method";
  static const String url = "url";
  static const String body = "body";
}

enum Command { setVip, checkVip, blinkLed, getFusionDevices }
