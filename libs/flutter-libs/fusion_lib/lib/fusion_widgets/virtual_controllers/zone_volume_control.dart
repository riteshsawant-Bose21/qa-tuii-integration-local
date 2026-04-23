import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart' hide Source;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_widgets/appbar/mobile_app_bar.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/source_item.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/view_model/controller_zone_view_model.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/volume_meter_painter.dart';

import 'bottomsheet_select_source.dart';
class VirtualControllerVolumeControl extends StatefulWidget {
  final bool isDesignMode;
  final bool isArc;
   VirtualControllerVolumeControl({
    super.key,
     this.isDesignMode = false,
     this.isArc = false
  });

  @override
  State<VirtualControllerVolumeControl> createState() => _VirtualControllerVolumeControlState();
}

class _VirtualControllerVolumeControlState extends State<VirtualControllerVolumeControl> {


  ValueNotifier<bool> controller = ValueNotifier(false);

  GlobalKey<VerticalAudioSliderState> key = GlobalKey<VerticalAudioSliderState>();

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: BlocBuilder<VirtualControllerViewModel, VirtualControllerState>(
          buildWhen: (previous, current) {
            return current is VirtualZoneSelected;
          },
          builder: (context, state) {

            if(state is VirtualZoneSelected) {
              WallZone selectedZone = state.zone;

              WallZoneSource? selectedSource = selectedZone.sources[state.currentSourceIndex-1] ?? null;
              WallSubZone selectSubZone = state.subZone;

              double volume = selectSubZone.ono.gain.toDouble() ?? 0;

              return Scaffold(
                backgroundColor: context.colorScheme.primaryBlack,
                appBar: CommonMobileAppBar(title: selectedZone.name),
                body: Container(
                  margin: const EdgeInsets.all(16),


                  child: Column(
                    children: [

                      /// Source Selector
                      BlocBuilder<VirtualControllerViewModel, VirtualControllerState>(
                          buildWhen: (previous, current) {
                            return current is SourceSelected;
                          },
                          builder: (context, selectSourceState) {
                            if(selectSourceState is SourceSelected){
                              selectedSource = selectSourceState.source;
                            }
                            return GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                      builder: (_) =>
                                          BottomSheetSelectSource(
                                            source: ValueNotifier(selectedSource!),
                                            sources: selectedZone.sources,
                                            onSelected: (WallZoneSource source) {
                                              context
                                                  .read<
                                                  VirtualControllerViewModel>()
                                                  .selectSource(
                                                  source,
                                                  selectSubZone.id ?? "",
                                                  "${selectedZone.functionId!}/selector",
                                                  sendToService: !widget.isDesignMode);

                                            },
                                          )
                                  );
                                },
                                child: SourceCard(source: selectedSource!)
                            );
                          }
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child:BlocBuilder<VirtualControllerViewModel, VirtualControllerState>(
                            buildWhen: (previous, current) {
                              return current is GainUpdated || current is SourceSelected;
                            },
                            builder: (context, gainState) {
                              bool muted = selectSubZone.ono.mute == 1 ? true:false;
                              bool fromServer=false;
                              if(gainState is GainUpdated){
                                volume = gainState.zoneSourceModel.ono.gain.toDouble();
                                muted = gainState.zoneSourceModel.ono.mute  == 1 ? true:false;
                                fromServer = gainState.fromServer;
                               // key.currentState!.animateTo(volume);
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.elevation1,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                      color: context.colorScheme.elevation2),
                                ),
                                child: Column(
                                  children: [

                                    /// Volume value
                                    widget.isArc ? SizedBox.shrink() : Text(
                                      volume.toInt().toString(),
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .h4Bold
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: muted ?  context.colorScheme.textDisabled :  volume != 0 ?
                                        context.colorScheme.textPrimary
                                            : context.colorScheme.volumeRed,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    /// Slider Row
                                    widget.isArc ?
                                    ArcVolumeMeter(volume: 70)
                                        : Expanded(
                                      child: Container(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            // Align(
                                            //   alignment: Alignment.center,
                                            //   child: _navButton(
                                            //     context: context,
                                            //     icon: Icons.chevron_left,
                                            //     onTap: () {
                                            //       context
                                            //           .read<
                                            //           VirtualControllerViewModel>()
                                            //           .previousSource(state.zoneIndex);
                                            //     },
                                            //   ),
                                            // ),
                                            Expanded(
                                                child: SizedBox(
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      FusionContainer(
                                                        raised: false,
                                                        borderRadius: 50,
                                                        child: Container(
                                                          width: 40,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 35,
                                                        child: Padding(
                                                          padding: EdgeInsetsGeometry
                                                              .symmetric(vertical: 5,
                                                              horizontal: 2),
                                                          child:VerticalAudioSlider(
                                                            key: key,
                                                            isMuted: muted,
                                                            initialValue: volume,
                                                            onChanged: (volume) {

                                                                context
                                                                    .read<
                                                                    VirtualControllerViewModel>()
                                                                    .updateVolume(
                                                                    selectSubZone!,
                                                                    volume,
                                                                    sendToService: !widget
                                                                        .isDesignMode);


                                                            },
                                                          )
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                            ),

                                            // Align(
                                            //   alignment: Alignment.center,
                                            //   child: _navButton(
                                            //     context: context,
                                            //     icon: Icons.chevron_right,
                                            //     onTap: () {
                                            //       context
                                            //           .read<
                                            //           VirtualControllerViewModel>()
                                            //           .nextSource(state.zoneIndex);
                                            //     },
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    /// Mute Button
                                    GestureDetector(
                                      onTap: () {
                                        context
                                            .read<
                                            VirtualControllerViewModel>()
                                            .updateVolume(selectSubZone!,volume,sendToService: !widget.isDesignMode,isMuted: !muted);
                                      },
                                      child: FusionContainer(
                                        raised: true,
                                        borderRadius: 8,
                                        child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment
                                                  .center,
                                              children: [
                                                Icon(!muted ? Icons
                                                    .volume_off : Icons.volume_up,
                                                    color: context.colorScheme
                                                        .iconDefault),
                                                const SizedBox(width: 10),
                                                Text(
                                                  !muted ? "Mute"
                                                      : "Unmute",
                                                  style: Theme
                                                      .of(context)
                                                      .textTheme
                                                      .l1Bold
                                                      .copyWith(
                                                    color: context.colorScheme
                                                        .textPrimary,
                                                  ),
                                                )
                                              ],
                                            )
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required BuildContext context,
    VoidCallback? onTap,

  }) {
    return GestureDetector(
      onTap: onTap,
      child: FusionContainer(
        raised:true,
        borderRadius: 8,
        child: Container(
          margin: EdgeInsets.all(8),
          child: Icon(
            icon,
            color: context.colorScheme.iconDefault,
          ),
        ),
      ),
    );
  }
}


class VerticalAudioSlider extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double>? onChanged;
  final bool isMuted;

  const VerticalAudioSlider({
    super.key,
    this.initialValue = 50,
    this.onChanged,
    required this.isMuted,
  });

  @override
  State<VerticalAudioSlider> createState() => VerticalAudioSliderState();
}

class VerticalAudioSliderState extends State<VerticalAudioSlider> with SingleTickerProviderStateMixin {
  late double value;
  double previousValue = 0;

  late AnimationController _controller;
  Animation<double>? _animation;
  @override
  void initState() {

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(() {
      setState(() {
        value = _animation!.value;
      });
      widget.onChanged?.call(value);
    });
    super.initState();
  }

  void _updateValue(Offset localPosition, double height) {
    double newValue = (1 - (localPosition.dy / height)) * 100;

    newValue = newValue.clamp(0, 100);

    setState(() => value = newValue);
    widget.onChanged?.call(newValue);
  }

  void animateTo(double target) {
    _animation = Tween<double>(
      begin: value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward(from: 0);
  }

  void toggleMute(bool onChange) {
    // if (value > 0) {
    //   previousValue = value;
    //   _animateTo(0);
    // } else {
    //   _animateTo(previousValue == 0 ? 50 : previousValue);
    // }
   // widget.onMuted?.call(!onChange);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    value = widget.initialValue;
    previousValue = value;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            _updateValue(details.localPosition, constraints.maxHeight);
          },
          onTapDown: (details) {
            _updateValue(details.localPosition, constraints.maxHeight);
          },
          child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter:  VolumeMeterPainterBG(
                value: value,
                trackColor: context.colorScheme.elevation2,
                gradientColors: widget.isMuted ?
                   [
                     context.colorScheme.textBody,
                  context.colorScheme.iconWhite
                ] : [

                  context.colorScheme.primary,
                  context.colorScheme.iconWhite
                ]

              )
          ),
        );
      },
    );
  }
}

class ArcVolumeSliderScreen extends StatefulWidget {
  const ArcVolumeSliderScreen({super.key});

  @override
  State<ArcVolumeSliderScreen> createState() => _ArcVolumeSliderScreenState();
}

class _ArcVolumeSliderScreenState extends State<ArcVolumeSliderScreen> {
  double _volume = 0.64;
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Container(
         // width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arc Meter
              SizedBox(
                height: 200,
                child: ArcVolumeMeter(volume: _isMuted ? 0.0 : _volume),
              ),
              const SizedBox(height: 32),
              // Linear Slider
              _buildLinearSlider(),
              const SizedBox(height: 20),
              // Mute Button
              _buildMuteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinearSlider() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 10,
        thumbShape: const _CustomThumbShape(),
        overlayShape: SliderComponentShape.noOverlay,
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: const Color(0xFF2E2E2E),
        thumbColor: Colors.white,
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Custom gradient active track
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth - 28;
              final fillWidth = trackWidth * (_isMuted ? 0.0 : _volume);
              return Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color(0xFF2E2E2E),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fillWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1DB954), Color(0xFF4ADE80)],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Slider(
            value: _isMuted ? 0.0 : _volume,
            onChanged: (v) {
              setState(() {
                _volume = v;
                _isMuted = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMuteButton() {
    return GestureDetector(
      onTap: () => setState(() => _isMuted = !_isMuted),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isMuted ? Icons.volume_off : Icons.volume_off_outlined,
              color: Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Mute',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Arc Meter ────────────────────────────────────────────────────────────────

class ArcVolumeMeter extends StatelessWidget {
  final double volume; // 0.0 – 1.0

  const ArcVolumeMeter({super.key, required this.volume});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArcPainter(volume: volume),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Text(
            '${(volume).round()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double volume;

  _ArcPainter({required this.volume});

  @override
  void paint(Canvas canvas, Size size) {
    const int totalTicks = 48;
    const double startAngle = pi; // left (180°)
    const double sweepAngle = pi; // half circle (180°)
    const double tickLength = 18.0;
    const double shortTickLength = 12.0;
    const double tickWidth = 2.8;
    const double gapFromArc = 4.0;

    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 20;

    final activeColor = const Color(0xFF2ECC71);
    final inactiveColor = const Color(0xFF3A3A3A);

    for (int i = 0; i < totalTicks; i++) {
      final fraction = i / (totalTicks - 1);
      final angle = startAngle + sweepAngle * fraction;

      final isActive = fraction <= volume;
      final isLong = i % 3 == 0;
      final tickLen = isLong ? tickLength : shortTickLength;

      final outerR = radius - gapFromArc;
      final innerR = outerR - tickLen;

      final outerX = center.dx + outerR * cos(angle);
      final outerY = center.dy + outerR * sin(angle);
      final innerX = center.dx + innerR * cos(angle);
      final innerY = center.dy + innerR * sin(angle);

      // Color with gradient effect on active ticks
      Color tickColor;
      if (isActive) {
        // slight fade at the leading edge
        final brightness = 0.65 + 0.35 * (fraction / volume.clamp(0.01, 1.0));
        tickColor = Color.lerp(
          activeColor.withOpacity(0.5),
          activeColor,
          brightness.clamp(0.0, 1.0),
        )!;
      } else {
        tickColor = inactiveColor;
      }

      final paint = Paint()
        ..color = tickColor
        ..strokeWidth = tickWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.volume != volume;
}

// ── Custom Thumb ─────────────────────────────────────────────────────────────

class _CustomThumbShape extends SliderComponentShape {
  const _CustomThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final canvas = context.canvas;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center + const Offset(0, 3), 14, shadowPaint);

    // White thumb
    final thumbPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 13, thumbPaint);
  }
}