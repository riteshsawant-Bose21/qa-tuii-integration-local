import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/appbar/mobile_app_bar.dart';


class MobileSnapshotsScreen extends StatefulWidget {
  final String title;
  final List<SnapshotsModel> snapshots;
  const MobileSnapshotsScreen({super.key,required this.title,this.snapshots=const []});

  @override
  State<MobileSnapshotsScreen> createState() => _MobileSnapshotsScreenState();
}

class _MobileSnapshotsScreenState extends State<MobileSnapshotsScreen> {
  int? selectedIndex;

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonMobileAppBar(title: 'Snapshot Group 1'),
      body: SnapshotsScreen(snapshots: widget.snapshots,),
    );
  }
}