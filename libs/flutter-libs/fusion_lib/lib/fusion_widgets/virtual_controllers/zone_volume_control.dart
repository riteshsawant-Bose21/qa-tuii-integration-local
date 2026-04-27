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

              WallZoneSource? selectedSource;
              if(selectedZone.sources.isNotEmpty) {
               selectedSource = selectedZone.sources?[state
                    .currentSourceIndex - 1] ?? null;
              }
              WallSubZone selectSubZone = state.subZone;

              double volume = selectSubZone.ono.gain.toDouble() ?? 0;

              return Scaffold(
                backgroundColor: context.colorScheme.primaryBlack,
                appBar: CommonMobileAppBar(title: selectSubZone.name,leadingIcon: widget.isArc ? SizedBox() :null),
                body: Container(
                  margin: const EdgeInsets.all(16),


                  child: Column(
                    children: [

                      /// Source Selector
                      if(selectedZone.sources.isNotEmpty)...[
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
                      ],

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
                                    Expanded(child: ArcVolumeMeter(
                                      onChanged: (value){
                                        print(value);
                                        context
                                            .read<
                                            VirtualControllerViewModel>()
                                            .updateVolume(
                                            selectSubZone!,
                                            value,
                                            sendToService: !widget
                                                .isDesignMode);
                                      },
                                      volume: volume,muted: muted
                                    ))
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

// ── Arc Meter ────────────────────────────────────────────────────────────────

class ArcVolumeMeter extends StatelessWidget {
  final double volume; // 0.0 – 1.0
  final bool muted; // 0.0 – 1.0
  final ValueChanged<double>? onChanged;
  const ArcVolumeMeter({super.key, this.onChanged, required this.volume,required this.muted});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ArcSlider(
          onChanged: onChanged!,
            value: volume, color: muted ? context.colorScheme.textDisabled : context.colorScheme.primary),
        Container(
          // padding: const EdgeInsets.only(top: 60),
          child: Text(
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
        )
      ],
    );
  }
}


class ArcSlider extends StatefulWidget {
  /// value = 0 to 100
  final double value;
  final Color color;
  final ValueChanged<double>? onChanged;

  const ArcSlider({
    super.key,
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  State<ArcSlider> createState() =>
      _ArcSliderState();
}

class _ArcSliderState extends State<ArcSlider> {
  late double volume; // 0 -> 100

  @override
  void initState() {
    super.initState();
    volume = widget.value.clamp(
      0.0,
      100.0,
    );
  }

  @override
  void didUpdateWidget(
      covariant ArcSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      volume = widget.value.clamp(
        0.0,
        100.0,
      );
    }
  }

  void _updateValue(
      Offset localPos,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height - 10,
    );

    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    double angle = atan2(dy, dx);

    if (angle < 0) {
      angle += 2 * pi;
    }

    if (angle < pi ||
        angle > 2 * pi) {
      return;
    }

    double progress =
        (angle - pi) / pi;

    progress =
        progress.clamp(0.0, 1.0);

    if (progress < 0.02) {
      progress = 0.0;
    }

    if (progress > 0.98) {
      progress = 1.0;
    }

    final value =
    (progress * 100).roundToDouble();

    setState(() {
      volume = value;
    });

    widget.onChanged?.call(
      volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(
          c.maxWidth,
          c.maxWidth / 2 + 30,
        );

        return GestureDetector(
          behavior:
          HitTestBehavior.opaque,
          onPanDown: (d) =>
              _updateValue(
                d.localPosition,
                size,
              ),
          onPanUpdate: (d) =>
              _updateValue(
                d.localPosition,
                size,
              ),
          child: CustomPaint(
            size: size,
            painter: _ArcPainter(
              volume: volume,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double volume; // 0-100
  final Color color;

  _ArcPainter({
    required this.volume,
    required this.color,
  });

  @override
  void paint(
      Canvas canvas,
      Size size) {
    const int totalTicks = 50;
    const double startAngle = pi;
    const double sweepAngle = pi;
    const double tickLength = 18;
    const double shortTickLength =
    12;
    const double tickWidth = 2.8;
    const double gapFromArc = 4;

    final center = Offset(
      size.width / 2,
      size.height - 10,
    );

    final radius =
        size.width / 2 - 20;

    final activeColor = color;
    final inactiveColor =
    const Color(0xFF3A3A3A);

    final progress =
        volume / 100;

    for (int i = 0;
    i < totalTicks;
    i++) {
      final fraction =
          i / (totalTicks - 1);

      final angle =
          startAngle +
              sweepAngle *
                  fraction;

      final isActive =
          fraction <= progress;

      final isLong =
          i % 3 == 0;

      final tickLen = isLong
          ? tickLength
          : shortTickLength;

      final outerR =
          radius - gapFromArc;

      final innerR =
          outerR - tickLen;

      final outerX =
          center.dx +
              outerR *
                  cos(angle);

      final outerY =
          center.dy +
              outerR *
                  sin(angle);

      final innerX =
          center.dx +
              innerR *
                  cos(angle);

      final innerY =
          center.dy +
              innerR *
                  sin(angle);

      Color tickColor;

      if (isActive) {
        final brightness =
            0.65 +
                0.35 *
                    (fraction /
                        progress.clamp(
                          0.01,
                          1.0,
                        ));

        tickColor = Color.lerp(
          activeColor.withOpacity(
            0.5,
          ),
          activeColor,
          brightness.clamp(
            0.0,
            1.0,
          ),
        )!;
      } else {
        tickColor =
            inactiveColor;
      }

      final paint = Paint()
        ..color = tickColor
        ..strokeWidth =
            tickWidth
        ..strokeCap =
            StrokeCap.round;

      canvas.drawLine(
        Offset(
          outerX,
          outerY,
        ),
        Offset(
          innerX,
          innerY,
        ),
        paint,
      );
    }

  }

  @override
  bool shouldRepaint(
      _ArcPainter old) =>
      old.volume != volume ||
          old.color != color;
}