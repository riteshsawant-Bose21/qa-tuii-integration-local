import 'package:flutter/material.dart';

import 'package:controllers/analog_controller.dart';
import 'package:controllers/widgets/error_boundary.dart';
import 'package:controllers/widgets/volume_slider.dart';

const remoteCC1MinVolume = 70;
const remoteCC1MaxVolume = 2450;
const remoteCC2MinVolume = 50;
const remoteCC2MaxVolumeA = 2450;
const remoteCC2MaxVolumeB = 1850;
const remoteCC2SelVolumeB = 3500;
const remoteCC3MinVolume = 1937;
const remoteCC3MaxVolume = 5;
const remoteCC3SelInput = 3650;

class CC1Controller extends StatefulWidget {
  final String host;
  final int port;
  final int position;

  const CC1Controller({
    super.key,
    required this.host,
    required this.port,
    required this.position,
  });

  @override
  State<CC1Controller> createState() => _CC1ControllerState();
}

class _CC1ControllerState extends State<CC1Controller> {
  late AnalogController controller;
  bool isConnected = false;
  String error = '';
  double volume = 0.5;

  @override
  void initState() {
    super.initState();
    controller = AnalogController(
      host: widget.host,
      port: widget.port,
      onError: (msg) => setState(() {
        error = msg;
        isConnected = false;
      }),
      onConnected: () => setState(() {
        isConnected = true;
        error = '';
      }),
    );
    controller.connect();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateVolume(double newVolume) {
    setState(() => volume = newVolume);

    final values = List<int>.filled(5, 0);
    final voltage =
        remoteCC1MinVolume + (remoteCC1MaxVolume - remoteCC1MinVolume) * volume;
    values[widget.position - 1] = voltage.round();

    controller.sendAnalogValues(values);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CC-1 Controller'),
          actions: [
            Icon(isConnected ? Icons.cloud_done : Icons.cloud_off),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            Center(
              child: VolumeSlider(
                value: volume,
                onChanged: updateVolume,
                label: 'Volume',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CC2Controller extends StatefulWidget {
  final String host;
  final int port;
  final int position;

  const CC2Controller({
    super.key,
    required this.host,
    required this.port,
    required this.position,
  });

  @override
  State<CC2Controller> createState() => _CC2ControllerState();
}

class _CC2ControllerState extends State<CC2Controller> {
  late AnalogController controller;
  bool isConnected = false;
  String error = '';
  double volume = 0.5;
  int selectedZone = 1;

  @override
  void initState() {
    super.initState();
    controller = AnalogController(
      host: widget.host,
      port: widget.port,
      onError: (msg) => setState(() {
        error = msg;
        isConnected = false;
      }),
      onConnected: () => setState(() {
        isConnected = true;
        error = '';
      }),
    );
    controller.connect();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateState() {
    final values = List<int>.filled(5, 0);

    if (widget.position == 1) {
      final maxVol =
          selectedZone == 2 ? remoteCC2MaxVolumeB : remoteCC2MaxVolumeA;
      final voltage =
          remoteCC2MinVolume + (maxVol - remoteCC2MinVolume) * volume;
      values[0] = voltage.round();

      if (selectedZone == 2) {
        values[3] = remoteCC2SelVolumeB;
      }
    } else if (widget.position == 2) {
      final maxVol =
          selectedZone == 2 ? remoteCC2MaxVolumeB : remoteCC2MaxVolumeA;
      final voltage =
          remoteCC2MinVolume + (maxVol - remoteCC2MinVolume) * volume;
      values[1] = voltage.round();

      if (selectedZone == 2) {
        values[4] = remoteCC2SelVolumeB;
      }
    }

    controller.sendAnalogValues(values);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CC-2 Controller'),
          actions: [
            Icon(isConnected ? Icons.cloud_done : Icons.cloud_off),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            VolumeSlider(
              value: volume,
              onChanged: (value) {
                setState(() => volume = value);
                updateState();
              },
              label: 'Volume',
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [selectedZone == 1, selectedZone == 2],
                  onPressed: (index) {
                    setState(() => selectedZone = index + 1);
                    updateState();
                  },
                  children: const [Text('A'), Text('B')],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Zone'),
          ],
        ),
      ),
    );
  }
}

class CC3Controller extends StatefulWidget {
  final String host;
  final int port;
  final int position;

  const CC3Controller({
    super.key,
    required this.host,
    required this.port,
    required this.position,
  });

  @override
  State<CC3Controller> createState() => _CC3ControllerState();
}

class _CC3ControllerState extends State<CC3Controller> {
  late AnalogController controller;
  bool isConnected = false;
  String error = '';
  double volume = 0.5;
  int selectedZone = 1;

  @override
  void initState() {
    super.initState();
    controller = AnalogController(
      host: widget.host,
      port: widget.port,
      onError: (msg) => setState(() {
        error = msg;
        isConnected = false;
      }),
      onConnected: () => setState(() {
        isConnected = true;
        error = '';
      }),
    );
    controller.connect();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateState() {
    final values = List<int>.filled(5, 0);

    if (widget.position == 1) {
      // Volume on line 0 (note CC3 works in reverse)
      final voltage = remoteCC3MinVolume -
          (remoteCC3MinVolume - remoteCC3MaxVolume) * volume;
      values[0] = voltage.round();

      // Input select lines 1-4
      for (int i = 1; i <= 4; i++) {
        if (i == selectedZone) {
          values[i] = remoteCC3SelInput - 100; // Below threshold
        } else {
          values[i] = remoteCC3SelInput + 100; // Above threshold
        }
      }
    }

    controller.sendAnalogValues(values);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CC-3 Controller'),
          actions: [
            Icon(isConnected ? Icons.cloud_done : Icons.cloud_off),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            VolumeSlider(
              value: volume,
              onChanged: (value) {
                setState(() => volume = value);
                updateState();
              },
              label: 'Volume',
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected:
                      List.generate(4, (index) => index + 1 == selectedZone),
                  onPressed: (index) {
                    setState(() => selectedZone = index + 1);
                    updateState();
                  },
                  children: const [Text('1'), Text('2'), Text('3'), Text('4')],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Zone'),
          ],
        ),
      ),
    );
  }
}

class AnalogControllerSelector extends StatelessWidget {
  final String host;
  final int port;

  const AnalogControllerSelector({
    super.key,
    required this.host,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analog Controllers')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CC1Controller(
                    host: host,
                    port: port,
                    position: 1,
                  ),
                ),
              ),
              child: const Text('CC-1 Controller'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CC2Controller(
                    host: host,
                    port: port,
                    position: 1,
                  ),
                ),
              ),
              child: const Text('CC-2 Controller'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CC3Controller(
                    host: host,
                    port: port,
                    position: 1,
                  ),
                ),
              ),
              child: const Text('CC-3 Controller'),
            ),
          ],
        ),
      ),
    );
  }
}
