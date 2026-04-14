import 'dart:io';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:flutter/material.dart';
import 'package:fusion_app/core/service_locator.dart';
import 'package:fusion_app/features/landing/viewmodel/project_view_model.dart';
import 'package:fusion_app/features/project/viewmodel/project_properties_view_model.dart';

class ProjectWorkArea extends StatefulWidget {
  const ProjectWorkArea({super.key});

  @override
  State<ProjectWorkArea> createState() => _ProjectWorkAreaState();
}

class _ProjectWorkAreaState extends State<ProjectWorkArea> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(
          title: serviceLocator<ProjectViewModel>().projectName,
        bottomWidget: false,
      ),
      body: SafeArea(
        child: Column(
          children: const [
            SizedBox(height: 12),
            _SegmentedSwitcher(),
            SizedBox(height: 12),
            Expanded(child: _PlanViewer()),
          ],
        ),
      ),
    );
  }
}

class _SegmentedSwitcher extends StatelessWidget {
  const _SegmentedSwitcher();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _SegmentItem(title: "Acoustics", selected: true),
          _SegmentItem(title: "System", selected: false),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String title;
  final bool selected;

  const _SegmentItem({
    required this.title,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF3D3C38)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PlanViewer extends StatelessWidget {
  const _PlanViewer();

  @override
  Widget build(BuildContext context) {
return Container();
    // return Container(
    //   color: Colors.white,
    //   child: InteractiveViewer(
    //     minScale: 0.8,
    //     maxScale: 4,
    //     child: Image.file(
    //        File(
    //            "${FusionUtils().appDirectory!.path}/${serviceLocator<ProjectViewModel>().floors.first.floorPlan.imagePath}"), // <-- your blueprint image
    //       fit: BoxFit.contain,
    //     ),
    //   ),
    // );
  }
}


