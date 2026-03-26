import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/widgets/bottomsheet_select_source.dart';
import 'package:fusion_app/features/zones/widgets/source_item.dart';
import 'package:fusion_app/features/zones/widgets/volume_meter_painter.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ZoneVolumeControl extends StatefulWidget {
  final List<ZoneModel> zones;
  final int zoneIndex;
  final String sourceId;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ValueChanged<int>? onVolumeChanged;
 // final ValueChanged<int>? onSourceChanged;

   const ZoneVolumeControl({
    super.key,
    required this.zones,
    required this.zoneIndex,
    required this.sourceId,
    this.onNext,
    this.onPrevious,
    this.onVolumeChanged,
   // this.onSourceChanged,
  });

  @override
  State<ZoneVolumeControl> createState() => _ZoneVolumeControlState();
}

class _ZoneVolumeControlState extends State<ZoneVolumeControl> {
  ZoneSourceModel? source;

  ValueNotifier<bool> controller = ValueNotifier(false);

  GlobalKey<VerticalAudioSliderState> key = GlobalKey<VerticalAudioSliderState>();

  int selectedZoneIndex = 0;
  ValueNotifier<int> selectedSourceIndex = ValueNotifier(0);
  String sourceId = "";
  @override
  void initState() {
    // TODO: implement initState
    selectedZoneIndex = widget.zoneIndex;
    sourceId = widget.sourceId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    // selectedZone = zones.firstWhere(
    //       (z) => z.sources.any((s) => s.id == id),
    // );
    source = widget.zones[selectedZoneIndex].sources.firstWhere(
          (s) => s.id == sourceId,
      orElse: () =>  widget.zones[selectedZoneIndex].sources.first
    );

    selectedSourceIndex = ValueNotifier(widget.zones[selectedZoneIndex].sources.indexWhere((s) => s.id == sourceId));

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: widget.zones[selectedZoneIndex].name),
        body: Container(
          margin: const EdgeInsets.all(16),


          child: Column(
            children: [
              /// Source Selector
              GestureDetector(
                onTap: (){
                  showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => BottomSheetSelectSource(
                          sources: widget.zones[selectedZoneIndex].sources,
                          onSelected: (int sourceIndex){
                           //widget.onSourceChanged!(index);
                           selectedSourceIndex.value = sourceIndex;
                           String id = widget.zones[selectedZoneIndex].sources[sourceIndex].id;
                           print("source!.name");
                           print(sourceIndex);
                           sourceId = id;
                           setState(() {

                           });
                          },
                          selectedIndex: selectedSourceIndex)
                  );
                },
                child: SourceCard(source: source!),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation1,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: context.colorScheme.elevation2),
                  ),
                  child: Column(
                    children: [

                      /// Volume value
                      ValueListenableBuilder(
                          valueListenable: controller,
                          builder: (context, value, child) {
                          return Text(
                            source!.volume.toString(),
                            style: Theme.of(context).textTheme.h4Bold.copyWith(
                              fontWeight: FontWeight.w700,
                              color: source!.volume != 0 ?
                              context.colorScheme.textPrimary
                                  : context.colorScheme.volumeRed,
                            ),
                          );
                        }
                      ),

                      const SizedBox(height: 24),

                      /// Slider Row
                      Expanded(
                        child: Container(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: _navButton(
                                  context: context,
                                  icon: Icons.chevron_left,
                                  onTap: (){
                                    print("selectedZoneIndex");
                                    print(selectedZoneIndex);
                                    if(selectedZoneIndex>0){
                                      selectedZoneIndex--;
                                      setState(() {

                                      });
                                    }

                                    widget.onPrevious!();
                                  },
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      FusionContainer(
                                        raised:false,
                                        borderRadius: 50,
                                        child: Container(
                                          width: 40,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 35,
                                        child: Padding(
                                          padding: EdgeInsetsGeometry.symmetric(vertical: 5,horizontal: 2),
                                          child: VerticalAudioSlider(
                                            key: key,
                                            initialValue: source!.volume.toDouble(),
                                            onChanged: (volume) {
                                              source = source!.copyWith(volume: volume.toInt());

                                              print("Volume: ${volume.toInt()}");
                                              widget.onVolumeChanged!(volume.toInt());
                                              controller.value = !controller.value;
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
                                  onTap: (){
                                    print("selectedZoneIndex");
                                    print(selectedZoneIndex);
                                   if(selectedZoneIndex < widget.zones.length-1){
                                     selectedZoneIndex++;
                                     setState(() {

                                     });
                                   }
                                    print("Updated Index: "+selectedZoneIndex.toString());

                                    widget.onNext!();
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
                        onTap: (){

                          key.currentState!.toggleMute();



                        },
                        child: FusionContainer(
                          raised:true,
                          borderRadius: 8,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ValueListenableBuilder(
                                valueListenable: controller,
                                builder: (context, value, child) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(source!.volume != 0 ?  Icons.volume_off : Icons.volume_up,
                                        color: context.colorScheme.iconDefault),
                                    const SizedBox(width: 10),
                                    Text(
                                      source!.volume != 0 ? "Mute" : "Unmute",
                                      style: Theme.of(context).textTheme.l1Bold.copyWith(
                                        color: context.colorScheme.textPrimary,
                                      ),
                                    )
                                  ],
                                );
                              }
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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