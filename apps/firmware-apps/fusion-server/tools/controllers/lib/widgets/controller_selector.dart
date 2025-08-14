import 'package:flutter/material.dart';

import 'package:controllers/widgets/analog_controllers.dart';
import 'package:controllers/widgets/digital_controllers.dart';

class ControllerSelector extends StatelessWidget {
  final String host;

  const ControllerSelector({
    super.key,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controllers')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalogControllerSelector(
                    host: host,
                    port: 8002,
                  ),
                ),
              ),
              child: const Text('Analog Controllers'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DigitalControllerSelector(
                    host: host,
                    port: 8003,
                  ),
                ),
              ),
              child: const Text('Digital Controllers'),
            ),
          ],
        ),
      ),
    );
  }
}
