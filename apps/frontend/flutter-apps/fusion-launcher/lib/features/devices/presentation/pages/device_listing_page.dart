import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../widgets/themostat_painter.dart';

// --- 1. DATA MODELS ---

class DeviceMetricRow {
  final String id;
  final bool isOnline;
  final String deviceName;
  final String model;
  final String location;
  final String ip;
  final String firmware;
  final int tempCelsius;
  final double diskUsage; // 0.0 to 1.0
  final double cpuUsage; // 0.0 to 1.0

  DeviceMetricRow({
    required this.id,
    required this.isOnline,
    required this.deviceName,
    required this.model,
    required this.location,
    required this.ip,
    required this.firmware,
    required this.tempCelsius,
    required this.diskUsage,
    required this.cpuUsage,
  });
}

class AlertItem {
  final String title;
  final String description;
  final String time;
  final String device;
  final String location;
  final Color severityColor; // Orange for warning, Red for critical

  AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.device,
    required this.location,
    required this.severityColor,
  });
}

// --- 2. THE MAIN TAB WIDGET ---

class DeviceListTab extends StatefulWidget {
  const DeviceListTab({super.key});

  @override
  State<DeviceListTab> createState() => _DeviceListTabState();
}

class _DeviceListTabState extends State<DeviceListTab> {
  // Sort State
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // Mock Data
  final List<DeviceMetricRow> _devices = <DeviceMetricRow>[
    DeviceMetricRow(
      id: '1',
      isOnline: true,
      deviceName: 'FM6-1',
      model: 'FusionMini FM6',
      location: 'Zone 1',
      ip: '192.168.50.100',
      firmware: 'v1.1',
      tempCelsius: 21,
      diskUsage: 0.43,
      cpuUsage: 0.71,
    ),
    DeviceMetricRow(
      id: '2',
      isOnline: true,
      deviceName: 'PSM8300-1',
      model: 'PowerSmart 8300',
      location: 'Zone 1',
      ip: '192.168.50.101',
      firmware: 'v2.1',
      tempCelsius: 30,
      diskUsage: 0.71,
      cpuUsage: 0.92,
    ),
    DeviceMetricRow(
      id: '3',
      isOnline: true,
      deviceName: 'CPLT-1',
      model: 'ControlPal Lt',
      location: 'Zone 2',
      ip: '192.168.50.102',
      firmware: 'v3.2',
      tempCelsius: 0,
      diskUsage: 0.92,
      cpuUsage: 0.43,
    ),
    DeviceMetricRow(
      id: '4',
      isOnline: false,
      deviceName: 'CPLT-2',
      model: 'ControlPal Lt',
      location: 'Zone 2',
      ip: '-',
      firmware: 'v3.2',
      tempCelsius: 0,
      diskUsage: 0.0,
      cpuUsage: 0.0,
    ),
  ];

  void _onSort<T>(Comparable<T> Function(DeviceMetricRow d) getField, int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _isAscending = !_isAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _isAscending = true;
      }
      _devices.sort((DeviceMetricRow a, DeviceMetricRow b) {
        final Comparable<T> aValue = getField(a);
        final Comparable<T> bValue = getField(b);
        return _isAscending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color cardDark = const Color(0xFF111111);
    final Color borderGrey = const Color(0xFF333333);
    final Color textGrey = const Color(0xFF9E9E9E);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // --- LEFT SIDE: DATA TABLE ---
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderGrey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1000),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.transparent),
                    dataRowColor: WidgetStateProperty.all(Colors.transparent),
                    columnSpacing: 24,
                    // Spacing between columns
                    horizontalMargin: 24,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _isAscending,
                    headingTextStyle: TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
                    border: TableBorder(
                      horizontalInside: BorderSide(color: borderGrey, width: 1),
                    ),
                    dividerThickness: 0.5,
                    columns: <DataColumn>[
                      _buildSortableHeader('STATUS', 0, (DeviceMetricRow d) => d.isOnline.toString()),
                      _buildSortableHeader('DEVICE NAME', 1, (DeviceMetricRow d) => d.deviceName),
                      _buildSortableHeader('MODEL', 2, (DeviceMetricRow d) => d.model),
                      _buildSortableHeader('LOCATION', 3, (DeviceMetricRow d) => d.location),
                      _buildSortableHeader('IP', 4, (DeviceMetricRow d) => d.ip),
                      _buildSortableHeader('FIRMWARE', 5, (DeviceMetricRow d) => d.firmware),
                      _buildSortableHeader('TEMP', 6, (DeviceMetricRow d) => d.tempCelsius),
                      _buildSortableHeader('DISK USE', 7, (DeviceMetricRow d) => d.diskUsage),
                      _buildSortableHeader('CPU USE', 8, (DeviceMetricRow d) => d.cpuUsage),
                      const DataColumn(label: Text('CONTROLS')),
                    ],
                    rows:
                        _devices.map((DeviceMetricRow device) {
                          return DataRow(
                            cells: <DataCell>[
                              DataCell(_buildStatusDot(device.isOnline)),
                              DataCell(_buildLinkText(device.deviceName)),
                              DataCell(Text(device.model)),
                              DataCell(Text(device.location)),
                              DataCell(Text(device.ip)),
                              DataCell(Text(device.firmware)),
                              // Temp
                              DataCell(
                                device.isOnline
                                    ? CompactThermostatWidget(
                                      temperature: device.tempCelsius,
                                      maxTemperature: 100, // Or whatever your max range is
                                    )
                                    : const Text("-"),
                              ),
                              // Disk Usage Canvas
                              DataCell(
                                device.isOnline
                                    ? UsageMeterWidget(
                                      value: device.diskUsage,
                                      label: "${(device.diskUsage * 100).toInt()}%",
                                      color: _getUsageColor(device.diskUsage),
                                    )
                                    : const Text("-"),
                              ),
                              // CPU Usage Canvas
                              DataCell(
                                device.isOnline
                                    ? UsageMeterWidget(
                                      value: device.cpuUsage,
                                      label: "${(device.cpuUsage * 100).toInt()}%",
                                      color: _getUsageColor(device.cpuUsage),
                                    )
                                    : const Text("-"),
                              ),
                              // Controls
                              DataCell(
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                      onPressed: () {},
                                      tooltip: 'Reboot',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // --- RIGHT SIDE: ALERTS SIDEBAR ---
        const Expanded(
          flex: 1,
          child: NotificationSidebar(),
        ),
      ],
    );
  }

  // Helper Methods
  DataColumn _buildSortableHeader(String label, int index, Comparable<dynamic> Function(DeviceMetricRow) getField) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label),
          if (_sortColumnIndex == index) ...<Widget>[
            const SizedBox(width: 4),
            Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.white),
          ],
        ],
      ),
      onSort: (int idx, _) => _onSort(getField, idx),
    );
  }

  Widget _buildStatusDot(bool isOnline) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLinkText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4CAF50),
        decoration: TextDecoration.underline,
        decorationColor: Color(0xFF4CAF50),
      ),
    );
  }

  Color _getUsageColor(double usage) {
    if (usage < 0.5) return const Color(0xFF4CAF50); // Green
    if (usage < 0.8) return const Color(0xFFFFC107); // Yellow/Orange
    return const Color(0xFFF44336); // Red
  }
}

// --- 3. REUSABLE CANVAS METER WIDGET ---

class UsageMeterWidget extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label;
  final Color color;

  const UsageMeterWidget({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: Alignment.topCenter,
          child: CustomPaint(
            size: const Size(40, 25), // 2:1 aspect ratio roughly (width > height)
            painter: SemiCircleGaugePainter(
              value: value,
              color: color,
              backgroundColor: const Color(0xFF424242), // Dark Grey track
            ),
          ),
        ),
        const SizedBox(width: 8),
        Align(
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class SemiCircleGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  SemiCircleGaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Setup Geometry
    // Center is bottom-middle of the canvas
    final Offset center = Offset(size.width / 2, size.height);
    // Radius is half the width
    final double radius = size.width / 2;
    // Thickness of the main arc track
    const double arcStrokeWidth = 5.0;

    // Angles: Sweep from 9 o'clock (Pi) to 3 o'clock (0)
    const double startAngle = math.pi;
    const double sweepAngle = math.pi;

    // 2. Draw Background Track (Grey Arc)
    final Paint backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = arcStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - arcStrokeWidth),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // 3. Draw Foreground Progress (Colored Arc)
    final Paint progressPaint =
        Paint()
          ..color = color
          ..strokeWidth = arcStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final double clampedValue = value.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - arcStrokeWidth),
      startAngle,
      sweepAngle * clampedValue,
      false,
      progressPaint,
    );

    // --- 4. Draw the Thinner, Floating Dial Stick ---

    final Paint pointerPaint =
        Paint()
          ..color =
              color // Match progress color
          ..strokeWidth =
              1.5 // <--- MADE THINNER (was 2.5)
          ..strokeCap = StrokeCap.round;

    // Calculate angle
    final double currentAngle = startAngle + (sweepAngle * clampedValue);

    // Dial Geometry Settings for "Floating" look
    // How far from the bottom center pivot to start drawing
    const double innerFloatDistance = 0;
    // How far from the outer arc edge to stop drawing
    const double outerGapDistance = 8.0;

    // Calculate start and end points
    final double innerRadius = innerFloatDistance;
    final double outerRadius = radius - arcStrokeWidth - outerGapDistance;

    // Start point (near bottom center, but floating)
    final Offset p1 = Offset(
      center.dx + innerRadius * math.cos(currentAngle),
      center.dy + innerRadius * math.sin(currentAngle),
    );

    // End point (pointing outwards, not touching arc)
    final Offset p2 = Offset(
      center.dx + outerRadius * math.cos(currentAngle),
      center.dy + outerRadius * math.sin(currentAngle),
    );

    canvas.drawLine(p1, p2, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant SemiCircleGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

// --- 4. RIGHT SIDEBAR WIDGET ---

class NotificationSidebar extends StatelessWidget {
  const NotificationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AlertItem> alerts = <AlertItem>[
      AlertItem(
        title: "Open Circuit Fault Chan...",
        description: "Open Circuit Fault Channel: 3,\nZone: Reception, Circuit: DM5SE",
        time: "Just now",
        device: "Powersmart 8300",
        location: "Equipment Location",
        severityColor: const Color(0xFFF44336), // Red
      ),
      AlertItem(
        title: "Lost communication wit...",
        description: "Lost communication with 'Main DSP'",
        time: "23 minutes ago",
        device: "Fusion Mini FM6",
        location: "Equipment Location",
        severityColor: const Color(0xFFFF9800), // Orange
      ),
      AlertItem(
        title: "High Temperature",
        description: "High Temperature",
        time: "1 hour ago",
        device: "Fusion Mini FM6",
        location: "Equipment Location",
        severityColor: const Color(0xFFFFC107), // Yellow
      ),
      AlertItem(
        title: "Signal Clipping - Mic/Lin...",
        description: "Signal Clipping - Mic/Line 2 (Source: Wireless Mic 1)",
        time: "Yesterday",
        device: "Fusion Mini FM6",
        location: "Equipment Location",
        severityColor: const Color(0xFFFFC107), // Yellow
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "ALERTS & NOTIFICATIONS",
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) => _buildAlertCard(alerts[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.shield_outlined, color: alert.severityColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: alert.severityColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  alert.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.description,
            style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: <Widget>[
              _buildFooterItem(Icons.dns, alert.device),
              _buildFooterItem(Icons.language, alert.location),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Colors.grey, size: 10),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}
