import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Panel displaying the virtual controller emulator
class VirtualControllerPanel extends StatefulWidget {
  const VirtualControllerPanel({super.key});

  @override
  State<VirtualControllerPanel> createState() => _VirtualControllerPanelState();
}

class _VirtualControllerPanelState extends State<VirtualControllerPanel> {
  double _volume = 64;
  bool _isMuted = false;
  String _selectedSource = 'Spotify';

  final List<String> _sources = <String>['Spotify', 'AirPlay', 'Bluetooth', 'Line In'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      builder: (BuildContext context, ConfigurationControlState state) {
        if (state is! ConfigControlLoaded) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// Header
              _buildHeader(context),

              /// Content
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.strokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          FusionAppText(text: 'VIRTUAL CONTROLLER', style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textBody)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConfigControlLoaded state) {
    final Zone? selectedZone =
        state.selectedZoneId != null
            ? state.zones.firstWhere(
              (Zone z) => z.id == state.selectedZoneId,
              orElse: () => state.zones.isNotEmpty ? state.zones.first : Zone(name: 'No Zone'),
            )
            : (state.zones.isNotEmpty ? state.zones.first : null);

    if (selectedZone == null) {
      return Center(
        child: FusionAppText(
          text: 'No zone selected',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colorScheme.strokeLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// Zone title
              FusionAppText(
                text: selectedZone.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              /// Source dropdown
              _buildSourceDropdown(context),
              const SizedBox(height: 24),

              /// Volume dial
              _buildVolumeDial(context),
              const SizedBox(height: 24),

              /// Volume slider
              _buildVolumeSlider(context),
              const SizedBox(height: 16),

              /// Mute button
              _buildMuteButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.radio_button_checked,
            size: 16,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSource,
                isExpanded: true,
                dropdownColor: context.colorScheme.elevation1,
                style: Theme.of(context).textTheme.bodyMedium,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: context.colorScheme.textSecondary,
                ),
                items:
                    _sources.map((String source) {
                      return DropdownMenuItem<String>(
                        value: source,
                        child: FusionAppText(
                          text: source,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedSource = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeDial(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 120,
      child: CustomPaint(
        painter: _VolumeMeterPainter(
          volume: _volume,
          primaryColor: context.colorScheme.primary,
          backgroundColor: context.colorScheme.elevation3,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: FusionAppText(
              text: _volume.toInt().toString(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        activeTrackColor: context.colorScheme.primary,
        inactiveTrackColor: context.colorScheme.elevation3,
        thumbColor: Colors.white,
      ),
      child: Slider(
        value: _volume,
        min: 0,
        max: 100,
        onChanged: (double value) {
          setState(() {
            _volume = value;
          });
        },
      ),
    );
  }

  Widget _buildMuteButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMuted = !_isMuted;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _isMuted ? context.colorScheme.error.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isMuted ? context.colorScheme.error : context.colorScheme.elevation3,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              size: 20,
              color: _isMuted ? context.colorScheme.error : context.colorScheme.textSecondary,
            ),
            const SizedBox(width: 8),
            FusionAppText(
              text: 'Mute',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _isMuted ? context.colorScheme.error : context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the volume meter arc
class _VolumeMeterPainter extends CustomPainter {
  final double volume;
  final Color primaryColor;
  final Color backgroundColor;

  _VolumeMeterPainter({
    required this.volume,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height;
    final double radius = size.width / 2 - 10;

    // Background arc
    final Paint bgPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Active arc based on volume
    final Paint activePaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    final double sweepAngle = (volume / 100) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      math.pi,
      sweepAngle,
      false,
      activePaint,
    );

    // Draw tick marks
    final Paint tickPaint =
        Paint()
          ..color = primaryColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    const int tickCount = 20;
    for (int i = 0; i <= tickCount; i++) {
      final double angle = math.pi + (i / tickCount) * math.pi;
      final double innerRadius = radius - 15;
      final double outerRadius = radius - 8;

      final double startX = centerX + innerRadius * math.cos(angle);
      final double startY = centerY + innerRadius * math.sin(angle);
      final double endX = centerX + outerRadius * math.cos(angle);
      final double endY = centerY + outerRadius * math.sin(angle);

      final bool isActive = (i / tickCount) <= (volume / 100);
      tickPaint.color = isActive ? primaryColor : backgroundColor;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeMeterPainter oldDelegate) {
    return oldDelegate.volume != volume;
  }
}
