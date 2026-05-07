import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ZoneVolumeControl extends StatefulWidget {

   const ZoneVolumeControl({
    super.key,
  });

  @override
  State<ZoneVolumeControl> createState() => _ZoneVolumeControlState();
}

class _ZoneVolumeControlState extends State<ZoneVolumeControl> {


  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return VirtualControllerVolumeControl();
  }

}
