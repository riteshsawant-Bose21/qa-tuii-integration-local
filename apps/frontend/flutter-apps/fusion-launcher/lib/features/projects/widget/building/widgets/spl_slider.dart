import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/view_model/spl_viewmodel.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_state.dart';
import 'package:fusion_launcher/features/projects/viewmodel/building_page_viewmodel.dart';
import 'package:fusion_lib/fusion_building_view/spl_range_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SplSlider extends StatelessWidget {
  const SplSlider({
    super.key,
    required this.splRangeController,
    required this.splPanelData,
  });

  final SplRangeController? splRangeController;
  final SplPanelData splPanelData;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: BlocBuilder<BuildingPageViewModel, BuildingPageState>(
        builder: (BuildContext context, BuildingPageState state) {
          final bool isShowingSpl = context.watch<BuildingPageViewModel>().isSplMode;
          if (!isShowingSpl) {
            return const SizedBox.shrink();
          }
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Align(
                alignment: Alignment.centerRight,
                child: SPLRangeSlider(
                  width: 24,
                  height: constraints.maxHeight,
                  controller: splRangeController,
                  minValue: serviceLocator<ProjectViewModel>().minSPL,
                  maxValue: serviceLocator<ProjectViewModel>().maxSPL,
                  invertedColors: splPanelData.splInvertColor,
                  onChanged: (double min, double max) {
                    context.read<SplViewModel>().startLoading();
                    // debugPrint("SPL Range changed: ${min.round()} - ${max.round()}");
                    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: min, autoSave: false);
                    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: max);
                    // if (!showLiveSpl) {
                    //   setState(() {
                    //     showLiveSpl = true;
                    //   });
                    // }
                  },
                  onChangeEnd: (double min, double max) {
                    context.read<SplViewModel>().stopLoading();

                    // debugPrint("SPL Range change ended: ${min.round()} - ${max.round()}");
                    serviceLocator<ProjectViewModel>().setMinSPL(minSPL: min, autoSave: false);
                    serviceLocator<ProjectViewModel>().setMaxSPL(maxSPL: max);
                    // serviceLocator<ProjectViewModel>().saveProjectToLocal();
                    // if (showLiveSpl) {
                    //   setState(() {
                    //     showLiveSpl = false;
                    //   });
                    // }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
