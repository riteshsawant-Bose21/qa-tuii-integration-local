import 'package:flutter/material.dart';

class DashboardDeviceTableHeader extends StatelessWidget {
  const DashboardDeviceTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const TextStyle headerStyle = TextStyle(color: Color(0xFF616161), fontSize: 10, fontWeight: FontWeight.bold);

    return const Padding(
      // MATCHED PADDING: Matches the internal padding of _buildDeviceRow (12.0)
      // plus the border width (1.0) to line up text perfectly.
      padding: EdgeInsets.symmetric(horizontal: 13.0),
      child: Row(
        children: <Widget>[
          // FLEX 4: Device Name
          Expanded(flex: 6, child: Text("DEVICE NAME", style: headerStyle)),
          // FLEX 2: Temp
          Expanded(flex: 2, child: Text("TEMP", style: headerStyle)),
          // FLEX 2: CPU
          Expanded(flex: 2, child: Text("CPU", style: headerStyle)),
          // FLEX 2: Disk
          Expanded(flex: 2, child: Text("DISK", style: headerStyle)),
          // FLEX 2: Controls
          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("CONTROLS", style: headerStyle))),
        ],
      ),
    );
  }
}
