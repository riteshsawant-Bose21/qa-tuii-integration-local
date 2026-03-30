// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_utils/fusion_utils.dart';

import '../../fusion_utils/app_enums.dart';
import '../../models/fusion_models.dart';

part './port_data/aes67_port_data.dart';
part './port_data/analog_port_data.dart';
part './port_data/aux_port_data.dart';
part './port_data/bluetooth_port_data.dart';
part './port_data/ethernet_port_data.dart';
part './port_data/fusion_connect_port_data.dart';
part './port_data/gpio_port_data.dart';
part './port_data/hdmi_port_data.dart';
part './port_data/loudspeaker_port_data.dart';
part './port_data/port_info.dart';
part './port_data/trs_port_data.dart';
part './port_data/usb_port_data.dart';
part './port_data/xlr_port_data.dart';

class ProductPortData {
  final Aes67PortData? aes67;
  final AnalogPortData? analog;
  final BluetoothPortData? bluetoothIo;
  final FusionConnectPortData? fusionConnect;
  final GPIOPortData? gpio;
  final HdmiPortData? hdmiIo;
  final USBPortData? usbIoPorts;
  final EthernetPortData? ethernetPorts;
  final AuxPortData? auxPorts;
  final LoudspeakerPortData? loudspeakerPorts;
  final XlrPortData? xlr;
  final TrsPortData? trs;
  ProductPortData({
    this.aes67,
    this.analog,
    this.bluetoothIo,
    this.fusionConnect,
    this.gpio,
    this.hdmiIo,
    this.usbIoPorts,
    this.ethernetPorts,
    this.auxPorts,
    this.loudspeakerPorts,
    this.xlr,
    this.trs,
  });

  ProductPortData copyWith({
    Aes67PortData? aes67,
    AnalogPortData? analog,
    BluetoothPortData? bluetoothIo,
    FusionConnectPortData? fusionConnect,
    GPIOPortData? gpio,
    HdmiPortData? hdmiIo,
    USBPortData? usbIoPorts,
    EthernetPortData? ethernetPorts,
    AuxPortData? auxPorts,
    LoudspeakerPortData? loudspeakerPorts,
    XlrPortData? xlr,
    TrsPortData? trs,
  }) {
    return ProductPortData(
      aes67: aes67 ?? this.aes67,
      analog: analog ?? this.analog,
      bluetoothIo: bluetoothIo ?? this.bluetoothIo,
      fusionConnect: fusionConnect ?? this.fusionConnect,
      gpio: gpio ?? this.gpio,
      hdmiIo: hdmiIo ?? this.hdmiIo,
      usbIoPorts: usbIoPorts ?? this.usbIoPorts,
      ethernetPorts: ethernetPorts ?? this.ethernetPorts,
      auxPorts: auxPorts ?? this.auxPorts,
      loudspeakerPorts: loudspeakerPorts ?? this.loudspeakerPorts,
      xlr: xlr ?? this.xlr,
      trs: trs ?? this.trs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'analog': analog?.toMap(),
      'aes67': aes67?.toMap(),
      'bluetooth_io': bluetoothIo?.toMap(),
      'fusion_connect': fusionConnect?.toMap(),
      'gpio': gpio?.toMap(),
      'ethernet': ethernetPorts?.toMap(),
      'hdmi_io': hdmiIo?.toMap(),
      'usb_io_ports': usbIoPorts?.toMap(),
      'aux_input': auxPorts?.toMap(),
      'loudspeaker': loudspeakerPorts?.toMap(),
      'XLR': xlr?.toMap(),
      'TRS': trs?.toMap(),
    };
  }

  factory ProductPortData.fromMap(Map<String, dynamic> map) {
    return ProductPortData(
      analog: DeserializationUtil.classDeserializer(AnalogPortData.fromMap).deserialize(map['analog']),
      fusionConnect: DeserializationUtil.classDeserializer(FusionConnectPortData.fromMap).deserialize(map['fusion_connect']),
      aes67: DeserializationUtil.classDeserializer(Aes67PortData.fromMap).deserialize(map['aes67']),
      gpio: DeserializationUtil.classDeserializer(GPIOPortData.fromMap).deserialize(map['gpio']),
      usbIoPorts: DeserializationUtil.classDeserializer(USBPortData.fromMap).deserialize(map['usb_io_ports']),
      bluetoothIo: DeserializationUtil.classDeserializer(BluetoothPortData.fromMap).deserialize(map['bluetooth_io']),
      hdmiIo: DeserializationUtil.classDeserializer(HdmiPortData.fromMap).deserialize(map['hdmi_io']),
      ethernetPorts: DeserializationUtil.classDeserializer(EthernetPortData.fromMap).deserialize(map['ethernet']),
      auxPorts: DeserializationUtil.classDeserializer(AuxPortData.fromMap).deserialize(map['aux_input']),
      loudspeakerPorts: DeserializationUtil.classDeserializer(LoudspeakerPortData.fromMap).deserialize(map['loudspeaker']),
      xlr: DeserializationUtil.classDeserializer(XlrPortData.fromMap).deserialize(map['XLR']),
      trs: DeserializationUtil.classDeserializer(TrsPortData.fromMap).deserialize(map['TRS']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductPortData.fromJson(String source) => ProductPortData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ProductPortData(aes67: $aes67, analog: $analog, bluetoothIo: $bluetoothIo, fusionConnect: $fusionConnect, gpio: $gpio, hdmiIo: $hdmiIo, usbIoPorts: $usbIoPorts, ethernetPorts: $ethernetPorts, auxPorts: $auxPorts, loudspeakerPorts: $loudspeakerPorts, xlr: $xlr, trs: $trs)';
  }

  @override
  bool operator ==(covariant ProductPortData other) {
    if (identical(this, other)) return true;

    return other.aes67 == aes67 &&
        other.analog == analog &&
        other.bluetoothIo == bluetoothIo &&
        other.fusionConnect == fusionConnect &&
        other.gpio == gpio &&
        other.hdmiIo == hdmiIo &&
        other.usbIoPorts == usbIoPorts &&
        other.ethernetPorts == ethernetPorts &&
        other.auxPorts == auxPorts &&
        other.loudspeakerPorts == loudspeakerPorts &&
        other.xlr == xlr &&
        other.trs == trs;
  }

  @override
  int get hashCode {
    return aes67.hashCode ^
        analog.hashCode ^
        bluetoothIo.hashCode ^
        fusionConnect.hashCode ^
        gpio.hashCode ^
        hdmiIo.hashCode ^
        usbIoPorts.hashCode ^
        ethernetPorts.hashCode ^
        auxPorts.hashCode ^
        loudspeakerPorts.hashCode ^
        xlr.hashCode ^
        trs.hashCode;
  }

  List<PortData> getInputPorts(ProductType productType, bool isPSM) {
    print(
      " Getting input ports for product type: $productType, isPSM: $isPSM.   RCA: ${analog?.ports?.rcaInput}, Analog: ${analog?.ports?.analogInput}, XLR: ${xlr?.inputs}, Loudspeaker: ${loudspeakerPorts?.inputs}, USB: ${usbIoPorts?.ports}, HDMI: ${hdmiIo?.inputs}, Aux: ${auxPorts?.ports}",
    );
    final input = [
      ...(analog?.ports?.rcaInput?.map(
            (e) => PortData(
              name: e.label,
              description: e.label,
              position: PortPosition.topLeft,
              portNumber: e.port,
              type: PortType.rcaInput,
            ),
          ) ??
          []),
      ...(analog?.ports?.analogInput?.map(
            (e) => PortData(
              name: e.label,
              description: e.label,
              position: PortPosition.topLeft,
              portNumber: e.port,
              type: switch (productType) {
                ProductType.speaker => PortType.analogOutput,
                ProductType.amplifier => isPSM ? PortType.dspAnalogInput : PortType.amplifierInput,
                ProductType.dsps => PortType.dspAnalogInput,
                ProductType.endpoints => PortType.endpointInput,

                _ => PortType.analogInput,
              },
            ),
          ) ??
          []),
    ];
    if (input.isEmpty) {
      input.addAll(
        List.generate(
          analog?.inputs ?? 0,
          (index) {
            final type = switch (productType) {
              ProductType.speaker => PortType.analogOutput,
              ProductType.amplifier => isPSM ? PortType.dspAnalogInput : PortType.amplifierInput,
              ProductType.dsps => PortType.dspAnalogInput,
              ProductType.endpoints => PortType.endpointInput,

              _ => PortType.analogInput,
            };
            return PortData(
              id: FusionUtils.shortStringUUID(),
              name: '${index + 1}',
              type: type,
              portNumber: index + 1,
              description: "${(type).description} ${index + 1}",
              position: PortPosition.topLeft,
              // compatibleTypes: switch (type) {
              //   PortType.analogOutput => [PortType.analogInput],
              //   PortType.amplifierInput => [PortType.amplifierOutput],
              //   PortType.dspAnalogInput => [PortType.dspAnalogOutput],
              //   PortType.endpointInput => [PortType.endpointOutput],
              //   _ => [],
              // },
            );
          },
        ),
      );
    }
    return [
      ...input,
      ...List.generate(
        xlr?.inputs ?? 0,
        (index) => PortData(
          id: FusionUtils.shortStringUUID(),
          name: '${index + 1}',
          type: PortType.xlrInput,
          portNumber: index + 1,
          description: "${(PortType.xlrInput).description} ${index + 1}",
          position: PortPosition.topLeft,
          // compatibleTypes: [PortType.xlrOutput],
        ),
      ),
      ...List.generate(
        loudspeakerPorts?.inputs ?? 0,
        (index) => PortData(
          id: FusionUtils.shortStringUUID(),
          name: '${index + 1}',
          type: PortType.circuitInput,
          portNumber: index + 1,
          description: "${(PortType.circuitInput).description} ${index + 1}",
          position: PortPosition.topLeft,
          // compatibleTypes: [PortType.speakerOutput],
        ),
      ),
      // ...List.generate((analog?.inputUnbalanced ?? 0), (index) {
      //   final type = PortType.audioJackInput;
      //   return PortData(
      //     id: FusionUtils.shortStringUUID(),
      //     name: '3.5mm Jack',
      //     type: type,
      //     portNumber: index + 1,
      //     description: "${(type).description} ${index + 1}",
      //     position: PortPosition.bottomLeft,

      //     compatibleTypes: [PortType.audioJackOutput],
      //   );
      // }),
      ...(usbIoPorts?.ports?.map(
            (e) => PortData(
              name: e.label,
              description: e.label,
              position: PortPosition.topLeft,
              portNumber: e.port,
              type: PortType.usbIn,
            ),
          ) ??
          []),
      ...(auxPorts?.ports?.map(
            (e) => PortData(
              name: e.label,
              description: e.label,
              position: PortPosition.topLeft,
              portNumber: e.port,
              type: PortType.audioJackInput,
            ),
          ) ??
          []),
      // ...List.generate(
      //   max(usbIoPorts?. ?? 0, usbIoPorts?.outputs ?? 0),
      //   (index) => PortData(
      //     id: FusionUtils.shortStringUUID(),
      //     name: 'USB ${index + 1}',
      //     type: PortType.usbIn,
      //     portNumber: index + 1,
      //     description: "${(PortType.usbIn).description} ${index + 1}",
      //     position: PortPosition.bottomLeft,
      //     // compatibleTypes: [PortType.usbOut],
      //   ),
      // ),
      ...List.generate(
        hdmiIo?.inputs ?? 0,
        (index) => PortData(
          id: FusionUtils.shortStringUUID(),
          name: 'HDMI',
          type: PortType.hdmiIn,
          portNumber: index + 1,
          description: "${(PortType.hdmiIn).description} ${index + 1}",
          position: PortPosition.bottomLeft,
          // compatibleTypes: [PortType.hdmiOut],
        ),
      ),
    ];
  }

  List<PortData> getOutputPorts(ProductType productType) {
    return [
      ...(analog?.ports?.analogOutputs?.map(
            (e) => PortData(
              name: e.label,
              description: e.label,
              position: PortPosition.topLeft,
              portNumber: e.port,
              type: switch (productType) {
                ProductType.speaker => PortType.analogInput,
                ProductType.amplifier => PortType.amplifierOutput,
                ProductType.dsps => PortType.dspAnalogOutput,
                _ => PortType.analogOutput,
              },
            ),
          ) ??
          []),
      // ...List.generate(
      //   analog?.outputs ?? 0,
      //   (index) {
      //     final type = switch (productType) {
      //       ProductType.speaker => PortType.analogInput,
      //       ProductType.amplifier => PortType.amplifierOutput,
      //       ProductType.dsps => PortType.dspAnalogOutput,
      //       _ => PortType.analogOutput,
      //     };
      //     return PortData(
      //       id: FusionUtils.shortStringUUID(),
      //       name: '${index + 1}',
      //       type: type,
      //       portNumber: index + 1,
      //       description: "${(type).description} ${index + 1}",
      //       position: PortPosition.topRight,
      //       // compatibleTypes: switch (type) {
      //       //   PortType.analogInput => [PortType.analogOutput],
      //       //   PortType.amplifierOutput => [PortType.circuitInput],
      //       //   PortType.dspAnalogOutput => [PortType.amplifierInput],
      //       //   _ => [],
      //       // },
      //     );
      //   },
      // ),
      ...List.generate(
        loudspeakerPorts?.outputs ?? 0,
        (index) => PortData(
          id: FusionUtils.shortStringUUID(),
          name: '${index + 1}',
          type: PortType.amplifierOutput,
          portNumber: index + 1,
          description: "${(PortType.amplifierOutput).description} ${index + 1}",
          position: PortPosition.topRight,
          // compatibleTypes: [PortType.circuitInput],
        ),
      ),

      ...List.generate(
        hdmiIo?.outputs ?? 0,
        (index) => PortData(
          id: FusionUtils.shortStringUUID(),
          name: 'HDMI',
          type: PortType.hdmiOut,
          portNumber: index + 1,
          description: "${(PortType.hdmiOut).description} ${index + 1}",
          position: PortPosition.bottomRight,
          // compatibleTypes: [PortType.hdmiIn],
        ),
      ),
    ];
  }

  List<PortData> get comPorts {
    final ports = <PortData>[];
    // if (hdmiIo != null) {
    //   ports.addAll(
    //     List.generate(
    //       hdmiIo?.inputs ?? 0,
    //       (index) => PortData(
    //         id: FusionUtils.shortStringUUID(),
    //         name: 'HDMI',
    //         type: PortType.hdmiIn,
    //         portNumber: ports.length + index + 1,
    //         description: "${(PortType.hdmiIn).description} ${index + 1}",
    //         position: PortPosition.footerLeft,
    //         compatibleTypes: [PortType.hdmiOut],
    //       ),
    //     ),
    //   );
    //   ports.addAll(
    //     List.generate(
    //       hdmiIo?.outputs ?? 0,
    //       (index) => PortData(
    //         id: FusionUtils.shortStringUUID(),
    //         name: 'HDMI',
    //         type: PortType.hdmiOut,
    //         portNumber: ports.length + index + 1,
    //         description: "${(PortType.hdmiOut).description} ${index + 1}",
    //         position: PortPosition.footerLeft,
    //         compatibleTypes: [PortType.hdmiIn],
    //       ),
    //     ),
    //   );
    // }
    if (bluetoothIo != null) {
      ports.addAll(
        List.generate(
          bluetoothIo?.inputs ?? 0,
          (index) => PortData(
            id: FusionUtils.shortStringUUID(),
            name: 'BT${index + 1}',
            type: PortType.bleIn,
            portNumber: ports.length + index + 1,
            description: "${(PortType.bleIn).description} ${index + 1}",
            position: PortPosition.footerLeft,
            // compatibleTypes: [PortType.bleOut],
          ),
        ),
      );
    }

    if (gpio != null) {
      ports.addAll(
        List.generate(
          gpio?.totalGpio ?? 0,
          (index) => PortData(
            id: FusionUtils.shortStringUUID(),
            name: '${index + 1}',
            type: PortType.gpioInput,
            portNumber: ports.length + index + 1,
            description: "GPIO ${index + 1}",
            position: PortPosition.footerRight,
            // compatibleTypes: [PortType.gpioOutput],
          ),
        ),
      );
      // ports.addAll(
      //   List.generate(
      //     gpio?.assignableOutputs ?? 0,
      //     (index) => PortData(
      //       id: FusionUtils.shortStringUUID(),
      //       name: 'GPIO OUT ${index + 1}',
      //       type: PortType.gpioOutput,
      //       portNumber: ports.length + index + 1,
      //       description: "${(PortType.gpioOutput).description} ${index + 1}",
      //       position: PortPosition.bottomRight,
      //       compatibleTypes: [PortType.gpioInput],
      //     ),
      //   ),
      // );
    }

    return ports;
  }
}
