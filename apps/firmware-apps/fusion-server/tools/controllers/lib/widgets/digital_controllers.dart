import 'package:flutter/material.dart';
import 'package:controllers/digital_controller.dart';
import 'package:controllers/widgets/error_boundary.dart';
import 'package:controllers/widgets/volume_slider.dart';

class CC1DController extends StatefulWidget {
  final String host;
  final int port;
  final String deviceId;

  const CC1DController({
    super.key,
    required this.host,
    required this.port,
    required this.deviceId,
  });

  @override
  State<CC1DController> createState() => _CC1DControllerState();
}

class _CC1DControllerState extends State<CC1DController> {
  late DigitalController controller;
  bool isConnected = false;
  String error = '';
  double volume = 0.5;
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    controller = DigitalController(
      host: widget.host,
      port: widget.port,
      onError: (msg) => setState(() {
        error = msg;
        isConnected = false;
      }),
      onConnected: () {
        setState(() {
          isConnected = true;
          error = '';
        });
        _subscribeToUpdates();
      },
    );
    controller.connect();
  }

  void _subscribeToUpdates() {
    controller.subscribe('gain', (value) {
      final level = double.tryParse(value) ?? 0.5;
      setState(() => volume = level);
    });

    controller.subscribe('mute', (value) {
      setState(() => isMuted = value == 'O');
    });
  }

  void _updateVolume(double newVolume) {
    setState(() => volume = newVolume);
    controller.setParam(widget.deviceId, 'gain', '1', newVolume.toString());
  }

  void _toggleMute() {
    final newState = !isMuted;
    setState(() => isMuted = newState);
    controller.setParam(widget.deviceId, 'mute', '2', newState ? 'O' : 'F');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CC-1D Controller'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: VolumeSlider(
                    value: volume,
                    onChanged: _updateVolume,
                    label: 'Volume',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CC2DController extends StatefulWidget {
  final String host;
  final int port;
  final String deviceId;

  const CC2DController({
    super.key,
    required this.host,
    required this.port,
    required this.deviceId,
  });

  @override
  State<CC2DController> createState() => _CC2DControllerState();
}

class _CC2DControllerState extends State<CC2DController> {
  late DigitalController controller;
  bool isConnected = false;
  String error = '';
  double volume = 0.5;
  String source = '1';
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    controller = DigitalController(
      host: widget.host,
      port: widget.port,
      onError: (msg) => setState(() {
        error = msg;
        isConnected = false;
      }),
      onConnected: () {
        setState(() {
          isConnected = true;
          error = '';
        });
        _subscribeToUpdates();
      },
    );
    controller.connect();
  }

  void _subscribeToUpdates() {
    controller.subscribe('gain', (value) {
      final level = double.tryParse(value) ?? 0.5;
      setState(() => volume = level);
    });

    controller.subscribe('source', (value) {
      setState(() => source = value);
    });

    controller.subscribe('mute', (value) {
      setState(() => isMuted = value == 'O');
    });
  }

  void _updateVolume(double newVolume) {
    setState(() => volume = newVolume);
    controller.setParam(widget.deviceId, 'gain', '1', newVolume.toString());
  }

  void _selectSource(String newSource) {
    setState(() => source = newSource);
    controller.setParam(widget.deviceId, 'source', '1', newSource);
  }

  void _toggleMute() {
    final newState = !isMuted;
    setState(() => isMuted = newState);
    controller.setParam(widget.deviceId, 'mute', '2', newState ? 'O' : 'F');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CC-2D Controller'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: VolumeSlider(
                    value: volume,
                    onChanged: _updateVolume,
                    label: 'Volume',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: ['1', '2'].map((s) => s == source).toList(),
                  onPressed: (index) => _selectSource((index + 1).toString()),
                  children: const [Text('A'), Text('B')],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Source'),
          ],
        ),
      ),
    );
  }
}

class CC3DController extends StatefulWidget {
  final String host;
  final int port;
  final String deviceId;

  const CC3DController({
    super.key,
    required this.host,
    required this.port,
    required this.deviceId,
  });

  @override
  State<CC3DController> createState() => _CC3DControllerState();
}

class _CC3DControllerState extends State<CC3DController> {
  late DigitalController controller;
  bool isConnected = false;
  String error = '';
  double volume = 0.5;
  String source = '1';
  bool isMuted = false;

  @override
  void initState() {
    super.initState();
    controller = DigitalController(
      host: widget.host,
      port: widget.port,
      onError: (msg) => setState(() {
        error = msg;
        isConnected = false;
      }),
      onConnected: () {
        setState(() {
          isConnected = true;
          error = '';
        });
        _subscribeToUpdates();
      },
    );
    controller.connect();
  }

  void _subscribeToUpdates() {
    controller.subscribe('gain', (value) {
      final level = double.tryParse(value) ?? 0.5;
      setState(() => volume = level);
    });

    controller.subscribe('source', (value) {
      setState(() => source = value);
    });

    controller.subscribe('mute', (value) {
      setState(() => isMuted = value == 'O');
    });
  }

  void _updateVolume(double newVolume) {
    setState(() => volume = newVolume);
    controller.setParam(widget.deviceId, 'gain', '1', newVolume.toString());
  }

  void _selectSource(String newSource) {
    setState(() => source = newSource);
    controller.setParam(widget.deviceId, 'source', '1', newSource);
  }

  void _toggleMute() {
    final newState = !isMuted;
    setState(() => isMuted = newState);
    controller.setParam(widget.deviceId, 'mute', '2', newState ? 'O' : 'F');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CC-3D Controller'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: VolumeSlider(
                    value: volume,
                    onChanged: _updateVolume,
                    label: 'Volume',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: List.generate(
                      4, (index) => (index + 1).toString() == source),
                  onPressed: (index) => _selectSource((index + 1).toString()),
                  children: const [Text('1'), Text('2'), Text('3'), Text('4')],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Source'),
          ],
        ),
      ),
    );
  }
}

class DigitalControllerSelector extends StatelessWidget {
  final String host;
  final int port;

  const DigitalControllerSelector({
    super.key,
    required this.host,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Controllers')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CC1DController(
                    host: host,
                    port: port,
                    deviceId: 'cc1d',
                  ),
                ),
              ),
              child: const Text('CC-1D Controller'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CC2DController(
                    host: host,
                    port: port,
                    deviceId: 'cc2d',
                  ),
                ),
              ),
              child: const Text('CC-2D Controller'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CC3DController(
                    host: host,
                    port: port,
                    deviceId: 'cc3d',
                  ),
                ),
              ),
              child: const Text('CC-3D Controller'),
            ),
          ],
        ),
      ),
    );
  }
}
