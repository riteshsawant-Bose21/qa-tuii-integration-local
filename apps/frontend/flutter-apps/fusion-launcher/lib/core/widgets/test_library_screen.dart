import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/fusion_theme_notifier.dart';

import '../../features/home/presentation/widgets/algorithms/amplifier_matching_widget.dart';
import '../../features/home/presentation/widgets/algorithms/ceiling_pendant_speaker_layout_widget.dart';
import '../../features/home/presentation/widgets/algorithms/circuiting_widget.dart';
import '../../features/home/presentation/widgets/algorithms/device_recommender_widget.dart';
import '../../features/home/presentation/widgets/algorithms/edgemax_speaker_layout_widget.dart';
import '../../features/home/presentation/widgets/algorithms/spl_calculation_widget.dart';
import '../../features/home/presentation/widgets/algorithms/surface_speaker_layout_widget.dart';
import '../../features/home/presentation/widgets/algorithms/tap_setting_widget.dart';
import '../../features/home/presentation/widgets/products_filter/product_filter.dart';

class TestLibraryScreen extends StatelessWidget {
  // text editing controller for the email field
  final TextEditingController emailController = TextEditingController();
  TestLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: context.smallGap, top: context.smallGap, bottom: context.smallGap),
      child: Column(
        children: <Widget>[
          FusionFlatContainer(
            color: context.colorScheme.elevation2,
            borderColor: context.colorScheme.elevation2,

            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Fusion Algorithms',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: FusionThemeController.themeModeNotifier,
                  builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
                    return IconButton(
                      onPressed: () {
                        final bool isLight = FusionThemeController.themeModeNotifier.value == ThemeMode.light;
                        FusionThemeController.setThemeMode(
                          isLight ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                      icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
                      tooltip: themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildAlgorithmsTab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmsTab(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Column(
        children: <Widget>[
          FusionFlatContainer(
            color: context.colorScheme.elevation2,
            borderColor: context.colorScheme.elevation2,
            padding: EdgeInsets.only(left: context.smallGap, right: context.smallGap, top: context.smallGap),
            child: TabBar(
              isScrollable: true,
              unselectedLabelColor: context.colorScheme.textGrey,
              
              tabs: <Widget>[
                const Tab(text: 'SPL Calculation'),
                const Tab(text: 'Tap Setting'),
                const Tab(text: 'Circuiting'),
                const Tab(text: 'Amp Matching'),
                // Tab(text: 'Enhanced Amp Matching'),
                const Tab(text: 'Device Recommender'),
                const Tab(text: 'Ceiling/Pendant Placement'),
                const Tab(text: 'Surface Placement'),
                const Tab(text: 'EdgeMax Placement'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: <Widget>[
                SplCalculationWidget(),
                TapSettingWidget(),
                CircuitingWidget(),
                AmplifierMatchingWidgetClean(),
                DeviceRecommenderWidget(),
                CeilingPendantSpeakerLayoutWidget(),
                SurfaceSpeakerLayoutWidget(),
                EdgeMaxSpeakerLayoutWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Main Products Filter Widget - Give it the remaining space
          Expanded(child: ProductFilterPage()),
        ],
      ),
    );
  }
}
