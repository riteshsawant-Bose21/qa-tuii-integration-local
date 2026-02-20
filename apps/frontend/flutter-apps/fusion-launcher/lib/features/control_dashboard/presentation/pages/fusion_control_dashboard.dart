import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../devices/presentation/pages/device_listing_page.dart';
import '../../../devices/presentation/widgets/themostat_painter.dart';
import '../widgets/dashboard_scroll_wrapper.dart';

class FusionControlDashboardPage extends StatelessWidget {
  const FusionControlDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgBlack = Color(0xFF000000);
    const Color cardDark = Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgBlack,
      body: DashboardScrollWrapper(
        minWidth: 1280, // Set this to the ideal width of your design
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ---------------------------------------------------------
              // LEFT COLUMN (Devices + Media + Events) - Flex 6
              // ---------------------------------------------------------
              Expanded(
                flex: 6,
                child: Column(
                  children: <Widget>[
                    // 1. DEVICES PANEL (Top Left)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: <Widget>[
                            _buildHeader("DEVICES", "View All"),
                            const SizedBox(height: 16),
                            _buildTableHeader(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView(
                                children: <Widget>[
                                  _buildDeviceRow(
                                    name: "Powersmart 8300",
                                    location: "Equipment Location",
                                    temp: 33,
                                    cpu: 0.92,
                                    disk: 0.92,
                                    alertMsg: "Open Circuit Fault Channel: 3 , Zone: Reception, Circuit: DM5SE",
                                    isCritical: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDeviceRow(
                                    name: "Powersmart 8300",
                                    location: "model name",
                                    temp: 46,
                                    cpu: 0.92,
                                    disk: 0.71,
                                    alertMsg: "High Temperature Warning",
                                    isWarning: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDeviceRow(
                                    name: "Powersmart 8300",
                                    location: "Equipment Location",
                                    temp: 21,
                                    cpu: 0.43,
                                    disk: 0.43,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDeviceRow(name: "Powersmart 8300", location: "Equipment Location", isOffline: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. BOTTOM ROW (Media + Events)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: <Widget>[
                          // MEDIA PLAYER
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: <Widget>[
                                  _buildHeader("MEDIA PLAYER", "View All"),
                                  const SizedBox(height: 16),
                                  _buildMediaCard("Morning Vibes", "Now playing", true),
                                  const SizedBox(height: 12),
                                  _buildMediaCard("Beast Mode", "", false),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // UPCOMING EVENTS
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                children: <Widget>[
                                  _buildHeader("UPCOMING EVENTS", "View All"),
                                  const SizedBox(height: 16),
                                  _buildEventCard("System Shutdown", "TODAY / 24 JULY, 2025 / 5:00PM", true),
                                  const SizedBox(height: 12),
                                  _buildEventCard("StartUP", "EVERYDAY / 24 JULY, 2025 / 5:00PM", false),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ---------------------------------------------------------
              // MIDDLE COLUMN (ZONES) - Flex 4
              // ---------------------------------------------------------
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: <Widget>[
                      _buildHeader("ZONES", ""),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: <Widget>[
                            _buildZoneCard("Zone1", "Reception", const Color(0xFF5C6BC0)),
                            const SizedBox(height: 16),
                            _buildZoneCard("Zone2_Fitness", "Cardio", const Color(0xFFEF5350)),
                            const SizedBox(height: 16),
                            _buildZoneCard("Zone3", "Reception", const Color(0xFFEF5350)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // ---------------------------------------------------------
              // RIGHT COLUMN (ALERTS) - Flex 3
              // ---------------------------------------------------------
              const Expanded(
                flex: 3,
                child: NotificationSidebar(), // Reusing your existing widget
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        if (action.isNotEmpty) Text(action, style: const TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.underline)),
      ],
    );
  }

  // --- DEVICE PANEL WIDGETS ---
  Widget _buildTableHeader() {
    const TextStyle headerStyle = TextStyle(color: Color(0xFF616161), fontSize: 10, fontWeight: FontWeight.bold);

    return const Padding(
      // MATCHED PADDING: Matches the internal padding of _buildDeviceRow (12.0)
      // plus the border width (1.0) to line up text perfectly.
      padding: EdgeInsets.symmetric(horizontal: 13.0),
      child: Row(
        children: <Widget>[
          // FLEX 4: Device Name
          Expanded(flex: 4, child: Text("DEVICE NAME", style: headerStyle)),
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

  Widget _buildDeviceRow({
    required String name,
    required String location,
    double temp = 0,
    double cpu = 0,
    double disk = 0,
    String? alertMsg,
    bool isCritical = false,
    bool isWarning = false,
    bool isOffline = false,
  }) {
    final Color bgColor = (isCritical || isWarning) ? const Color(0xFF1E1E1E) : const Color(0xFF161616);
    final Color borderColor = Colors.white.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            // PADDING: 12.0 horizontal (Matches Header's effective padding)
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              children: <Widget>[
                // 1. Device Info (FLEX 4 - MATCHES HEADER)
                Expanded(
                  flex: 4,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
                        child: const Icon(Icons.router, color: Colors.white54, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Metrics (FLEX 2 EACH - MATCHES HEADER)
                Expanded(
                  flex: 2,
                  child:
                      isOffline
                          ? _buildDash()
                          : Align(
                            alignment: Alignment.centerLeft,
                            child: CompactThermostatWidget(temperature: temp.toInt(), maxTemperature: 100),
                          ),
                ),
                Expanded(
                  flex: 2,
                  child: isOffline ? _buildDash() : UsageMeterWidget(value: cpu, label: "${(cpu * 100).toInt()}%", color: _getUsageColor(cpu)),
                ),
                Expanded(
                  flex: 2,
                  child: isOffline ? _buildDash() : UsageMeterWidget(value: disk, label: "${(disk * 100).toInt()}%", color: _getUsageColor(disk)),
                ),

                // 3. Controls (FLEX 2 - MATCHES HEADER)
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      _buildMiniControl(Icons.settings_power),
                      const SizedBox(width: 10),
                      _buildMiniControl(Icons.refresh),
                      const SizedBox(width: 10),
                      _buildMiniControl(Icons.more_vert),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alert Banner code remains same...
          if (alertMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCritical ? const Color(0xFF3E1A1A) : const Color(0xFF3E2E1A),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
                    color: isCritical ? const Color(0xFFE57373) : const Color(0xFFFFB74D),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alertMsg,
                      style: TextStyle(color: isCritical ? const Color(0xFFE57373) : const Color(0xFFFFB74D), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDash() => const Align(alignment: Alignment.centerLeft, child: Text("-", style: TextStyle(color: Colors.grey)));

  Widget _buildMiniControl(IconData icon) {
    return FusionNeumorphicButton(
      width: 26,
      height: 26,
      borderRadius: 6,
      onTap: () {
        // Handle click action here
        print("Clicked $icon");
      },
      child: Icon(
        icon,
        size: 13,
        color: const Color(0xFF888888),
      ),
    );
  }

  // --- ZONE WIDGETS ---
  Widget _buildZoneCard(String zoneName, String label, Color accentColor, {bool isExpanded = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414), // Very dark card bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: <Widget>[
          // --- HEADER (Zone Name + Icon) ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    Text(zoneName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.drag_indicator, color: Colors.grey[800], size: 18),
              ],
            ),
          ),

          // --- CONTENT (Sliders & Meters) ---
          // Assuming isExpanded shows content, otherwise just header
          // For demo, we show content always if you prefer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),

                // 1. Label + Audio Meter Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    // Label
                    SizedBox(
                      width: 80, // Fixed width for alignment
                      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    // The Custom Animated Meter
                    const Expanded(
                      child: AudioMeterWidget(height: 32),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Mute Btn + Slider + Value Row
                Row(
                  children: <Widget>[
                    // Neumorphic Mute Button
                    FusionNeumorphicButton(
                      width: 32,
                      height: 32,
                      borderRadius: 8,
                      onTap: () {},
                      child: const Icon(
                        Icons.volume_off,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Slider
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.grey[800],
                          thumbColor: Colors.white,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, elevation: 2),
                        ),
                        child: Slider(
                          value: 0.72,
                          onChanged: (double v) {},
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Value Text
                    const SizedBox(
                      width: 24,
                      child: Text(
                        "72",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MEDIA & EVENT CARDS ---

  Widget _buildMediaCard(String title, String status, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(color: isPlaying ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.equalizer, color: Colors.grey, size: 20), // Placeholder for waveform
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                if (status.isNotEmpty) Text(status, style: const TextStyle(color: Colors.green, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.tune, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  // --- UPDATED EVENT CARD TO MATCH REFERENCE IMAGE ---

  Widget _buildEventCard(String title, String date, bool isAction) {
    // Theme colors matching the dashboard
    const Color cardColor = Color(0xFF222222);
    const Color accentColor = Color(0xFF4CAF50); // Green accent
    const Color textColor = Colors.white;
    const MaterialColor subTextColor = Colors.grey;

    return Container(
      // The main card background and rounding
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      // Clip behavior ensures the accent bar doesn't bleed out of rounded corners
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        // Ensures the row stretches to fit the tallest element
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. The Vertical Accent Bar
            Container(
              width: 4,
              color: accentColor,
            ),

            // 2. Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Title and Edit Icon Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(title, style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        // Neumorphic Edit Icon (using your existing wrapper if available)
                        // Or standard icon for now:
                        FusionNeumorphicButton(
                          width: 26,
                          height: 26,
                          borderRadius: 6,
                          onTap: () {
                            // Handle click action here
                            print("Clicked Edit Event");
                          },
                          child: const Icon(Icons.mode_edit_outlined, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Date / Subtitle
                    Text(date, style: const TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w400)),

                    // Action Buttons (only if isAction is true)
                    if (isAction) ...<Widget>[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FusionNeumorphicButton(
                            width: 100,
                            height: 26,
                            borderRadius: 6,
                            onTap: () {
                              // Handle click action here
                              print("Clicked Run Now");
                            },
                            child: _buildTextActionButton("Run Now", Colors.white),
                          ),
                          const SizedBox(width: 16),
                          _buildTextActionButton("Cancel", subTextColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New helper for the subtle text-based action buttons
  Widget _buildTextActionButton(String label, Color color) {
    return InkWell(
      onTap: () {}, // Add action handler
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Color _getUsageColor(double val) {
    if (val < 0.5) return const Color(0xFF4CAF50);
    if (val < 0.8) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  Color _getZoneColor(String name) {
    if (name.contains("1")) return const Color(0xFF5C6BC0);
    if (name.contains("2")) return const Color(0xFFEF5350);
    if (name.contains("3")) return const Color(0xFFFFCA28);
    return const Color(0xFF66BB6A);
  }
}

class AudioMeterWidget extends StatefulWidget {
  final double height;
  final bool isAnimate; // To turn off animation if needed

  const AudioMeterWidget({
    super.key,
    this.height = 36, // Total height including labels
    this.isAnimate = true,
  });

  @override
  State<AudioMeterWidget> createState() => _AudioMeterWidgetState();
}

class _AudioMeterWidgetState extends State<AudioMeterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _currentLevel = 0.3; // Start partially filled (not 0) to avoid initial jump
  double _targetLevel = 0.3;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat();

    _controller.addListener(_updatePhysics);
  }

  void _updatePhysics() {
    if (!widget.isAnimate) return;

    setState(() {
      // 1. GENERATE NEW TARGET
      // If we are close to the target, pick a new random volume level
      if ((_targetLevel - _currentLevel).abs() < 0.02) {
        // Pick a value between 0.4 and 0.95 (Active "Talking" range)
        _targetLevel = 0.4 + (_random.nextDouble() * 0.55);
      }

      // 2. APPLY PHYSICS (Attack & Decay)
      if (_targetLevel > _currentLevel) {
        // ATTACK: Move UP fast (0.15 speed)
        // This makes the meter responsive to "loud" sounds
        _currentLevel += (_targetLevel - _currentLevel) * 0.15;
      } else {
        // DECAY: Move DOWN slow (0.03 speed)
        // This is the key to removing flicker! It lingers before dropping.
        _currentLevel += (_targetLevel - _currentLevel) * 0.03;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _AudioMeterPainter(level: _currentLevel),
      ),
    );
  }
}

class _AudioMeterPainter extends CustomPainter {
  final double level;

  _AudioMeterPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    const double barHeight = 12.0;
    const double tickHeight = 4.0;

    // 1. Draw Background Track (Dark Grey container for the meter)
    final Paint bgPaint =
        Paint()
          ..color = const Color(0xFF2A2A2A)
          ..style = PaintingStyle.fill;

    final RRect bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, barHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Draw Active Gradient Level
    // We create a LinearGradient shader from Green -> Yellow -> Red
    final Shader gradient = const LinearGradient(
      colors: <Color>[
        Color(0xFF4CAF50), // Green (-60)
        Color(0xFF66BB6A), // Lighter Green
        Color(0xFFFFCA28), // Yellow (-24)
        Color(0xFFEF5350), // Red (-00)
      ],
      stops: <double>[0.0, 0.4, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, barHeight));

    final Paint activePaint =
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill;

    // Calculate width based on level (0.0 to 1.0)
    final double activeWidth = size.width * level;

    final RRect activeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, activeWidth, barHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(activeRect, activePaint);

    // 3. Draw Peak Indicator (Optional: A small white line at the tip)
    final Paint peakPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..strokeWidth = 2;
    canvas.drawLine(Offset(activeWidth, 0), Offset(activeWidth, barHeight), peakPaint);

    // 4. Draw Ticks and Labels
    final Paint tickPaint =
        Paint()
          ..color = Colors.grey[700]!
          ..strokeWidth = 1.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Labels from reference image
    final List<String> labels = <String>["-60", "-48", "-36", "-24", "-12", "-00"];

    // Evenly distribute them
    for (int i = 0; i < labels.length; i++) {
      // Calculate X position (normalize i from 0 to 1)
      // We inset slightly so -60 and -00 aren't on the absolute edge
      final double x = (size.width * (i / (labels.length - 1)));

      // Draw Tick
      canvas.drawLine(
        Offset(x, barHeight),
        Offset(x, barHeight + tickHeight),
        tickPaint,
      );

      // Draw Text
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Colors.grey[600], fontSize: 9),
      );
      textPainter.layout();

      // Center text on the tick
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), barHeight + tickHeight + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _AudioMeterPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}
