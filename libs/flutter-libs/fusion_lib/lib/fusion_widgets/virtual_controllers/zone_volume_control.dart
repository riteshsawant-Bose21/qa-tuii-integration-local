import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart' hide Source;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_widgets/appbar/mobile_app_bar.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/source_item.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/view_model/controller_zone_view_model.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/volume_meter_painter.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/widgets/arc_slider.dart';
import 'package:fusion_lib/fusion_widgets/virtual_controllers/widgets/vertical_slider.dart';

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



