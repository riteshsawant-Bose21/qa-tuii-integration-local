import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/view_model/controlpal_zone_view_model.dart';
import 'package:fusion_app/features/zones/widgets/bottomsheet_select_source.dart';
import 'package:fusion_app/features/zones/widgets/source_item.dart';
import 'package:fusion_app/features/zones/widgets/volume_meter_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class ZoneVolumeControl extends StatefulWidget {
  // final List<ZoneModel> zones;
  // final int zoneIndex;
  // final String sourceId;
  // final VoidCallback? onNext;
  // final VoidCallback? onPrevious;
  // final ValueChanged<int>? onVolumeChanged;
 // final ValueChanged<int>? onSourceChanged;

   const ZoneVolumeControl({
    super.key,
    // required this.zones,
    // required this.zoneIndex,
    // required this.sourceId,
    // this.onNext,
    // this.onPrevious,
    // this.onVolumeChanged,
   // this.onSourceChanged,
  });

  @override
  State<ZoneVolumeControl> createState() => _ZoneVolumeControlState();
}

class _ZoneVolumeControlState extends State<ZoneVolumeControl> {


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
      child: BlocBuilder<ControlPalZonesViewModel, ControlPalZonesState>(
          buildWhen: (previous, current) {
            return current is ZoneSelected;
          },
          builder: (context, state) {
            if(state is ZoneSelected) {
              ZoneModel selectedZone = state.zone;
              ZoneSourceModel selectedSource = selectedZone.sources[state.currentSourceIndex];

              return Scaffold(
                backgroundColor: context.colorScheme.primaryBlack,
                appBar: CommonAppBar(title: selectedZone.name),
                body: Container(
                  margin: const EdgeInsets.all(16),


                  child: Column(
                    children: [

                      /// Source Selector
                      BlocBuilder<ControlPalZonesViewModel, ControlPalZonesState>(
                          buildWhen: (previous, current) {
                            return current is SourceSelected;
                          },
                          builder: (context, selectSourceState) {
                            if(selectSourceState is SourceSelected){
                              selectedSource = selectSourceState.zoneSourceModel;
                            }
                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) =>
                                      BottomSheetSelectSource(
                                        source: ValueNotifier(selectedSource),
                                          sources: selectedZone.sources,
                                          onSelected: (ZoneSourceModel source) {
                                            context
                                                .read<
                                                ControlPalZonesViewModel>()
                                                .selectSource(source);

                                          },
                                        )
                              );
                            },
                            child: SourceCard(source: selectedSource)
                          );
                        }
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child:BlocBuilder<ControlPalZonesViewModel, ControlPalZonesState>(
                            buildWhen: (previous, current) {
                              return current is GainUpdated || current is SourceSelected;
                            },
                            builder: (context, gainState) {
                              double volume = selectedSource.volume;
                              if(gainState is GainUpdated){
                                volume = gainState.zoneSourceModel.volume;
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
                                  Text(
                                    volume.toInt().toString(),
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .h4Bold
                                        .copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: volume != 0 ?
                                      context.colorScheme.textPrimary
                                          : context.colorScheme.volumeRed,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  /// Slider Row
                                  Expanded(
                                    child: Container(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          Align(
                                            alignment: Alignment.center,
                                            child: _navButton(
                                              context: context,
                                              icon: Icons.chevron_left,
                                              onTap: () {
                                                context
                                                    .read<
                                                    ControlPalZonesViewModel>()
                                                    .previousSource(state.zoneIndex);
                                              },
                                            ),
                                          ),
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
                                                        child: VerticalAudioSlider(
                                                          key: key,
                                                          initialValue: selectedSource.volume.toDouble(),
                                                          onChanged: (volume) {




                                                            context
                                                                .read<
                                                                ControlPalZonesViewModel>()
                                                                .updateVolume(state.zoneIndex,selectedSource,volume);

                                                          },
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                          ),

                                          Align(
                                            alignment: Alignment.center,
                                            child: _navButton(
                                              context: context,
                                              icon: Icons.chevron_right,
                                              onTap: () {
                                                context
                                                    .read<
                                                    ControlPalZonesViewModel>()
                                                    .nextSource(state.zoneIndex);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  /// Mute Button
                                  GestureDetector(
                                    onTap: () {
                                      key.currentState!.toggleMute();
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
                                            Icon(volume != 0 ? Icons
                                                .volume_off : Icons.volume_up,
                                                color: context.colorScheme
                                                    .iconDefault),
                                            const SizedBox(width: 10),
                                            Text(
                                              volume != 0
                                                  ? "Mute"
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

  const VerticalAudioSlider({
    super.key,
    this.initialValue = 50,
    this.onChanged,
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
    value = widget.initialValue;
    previousValue = value;
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

  void _animateTo(double target) {
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

  void toggleMute() {
    if (value > 0) {
      previousValue = value;
      _animateTo(0);
    } else {
      _animateTo(previousValue == 0 ? 50 : previousValue);
    }
    widget.onChanged?.call(value);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
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
              gradientColors: [
                context.colorScheme.primary,
                context.colorScheme.iconWhite,

              ],
            )
          ),
        );
      },
    );
  }
}