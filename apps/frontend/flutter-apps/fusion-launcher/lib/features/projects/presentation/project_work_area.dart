import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/bill_of_materials/presentation/bill_of_materials_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/pages/audio_system_design_page.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/dock_item_config.dart';

import '../../../core/service_locator.dart';
import '../../../core/utils/broadcast_controllers.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../schematics/presentation/pages/schematics_page.dart';
import '../../venue_design/presentation/widgets/side_panel/product_query.dart';
import '../widget/building/building_canvas.dart';
import '../widget/control_design_tab_switcher.dart';

class ProjectWorkArea extends StatefulWidget {
  const ProjectWorkArea({super.key});

  @override
  State<ProjectWorkArea> createState() => _TestLibraryScreenState();
}

class _TestLibraryScreenState extends State<ProjectWorkArea> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  StreamSubscription<int>? subscription;
  late TextEditingController _projectNameController;
  final List<Widget> _tabs = const <Widget>[
    Tab(text: 'Building'),
    Tab(text: 'Schematics'),
    Tab(text: 'Budget'),
    Tab(text: 'Configuration'),
    Tab(text: 'Cloud'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      animationDuration: Duration.zero,
    );

    subscription = projectTabBroadcastController.stream.listen((int index) {
      if (index >= 0 && index < _tabController.length) {
        _tabController.animateTo(index);
      }
    });
    _projectNameController = TextEditingController(text: serviceLocator<ProjectViewModel>().projectName);
  }

  @override
  void dispose() {
    _tabController.dispose();
    subscription?.cancel();
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      animationDuration: Duration.zero,

      length: 4,
      child: Scaffold(
        appBar: FusionAppBar(
          backgroundColor: Colors.black87,
          leading: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 50,
              height: 50,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () {
                  serviceLocator<ProjectViewModel>().closeProject();
                  Navigator.of(context).pop();
                },
                tooltip: 'Back to projects',
              ),
            ),
          ), // List icon

          title: IntrinsicWidth(
            child: TextField(
              controller: _projectNameController,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Project Name',
                suffixIcon: Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.grey,
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              onSubmitted: (String value) {
                serviceLocator<ProjectViewModel>().setProjectName(value.trim());
              },
            ),
          ),

          actions: <Widget>[
            const FusionProfileImage(
              assetPath: "assets/images/fusion_default_icon.png",
              size: 24,
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            /// Tab Bar Section
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                border: Border.all(color: Theme.of(context).colorScheme.dividerColor, width: 1),
              ),
              child: Row(
                children: <Widget>[
                  /// Project Name Section
                  _projectNameSection(),

                  /// Tabs Section
                  Expanded(
                    child: TabBar(
                      labelColor: Colors.black87,
                      unselectedLabelColor: Theme.of(context).colorScheme.grey,
                      dividerColor: Colors.transparent,
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Colors.black,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      labelPadding: const EdgeInsets.only(left: 32),
                      tabs: _tabs,
                    ),
                  ),

                  /// Share Icon Section
                  Container(
                    width: 56,
                    height: 48,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      // border horizontal
                      border: Border(
                        left: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                        right: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
                      ),
                    ),
                    child: Image.asset(
                      "assets/images/share_icon.png",
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const ControlDesignTabSwitcher(),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  /// building tab with docking area
                  FusionDockableArea(
                    tabKey: "tab1",
                    showLeft: true,
                    showRight: true,
                    mainArea: const BuildingCanvas(),
                    dockItemList: <DockItemConfig>[
                      DockItemConfig(
                        id: "1",
                        title: "Coverage",
                        side: "left",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                      DockItemConfig(
                        id: "2",
                        title: "Devices",
                        side: "left",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                      DockItemConfig(
                        id: "3",
                        title: "ATTRIBUTES",
                        side: "right",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                      DockItemConfig(
                        id: "4",
                        title: "COST CALCULATOR",
                        side: "right",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                      DockItemConfig(
                        id: "5",
                        title: "PRODUCT QUERY",
                        side: "right",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                      DockItemConfig(
                        id: "6",
                        title: "DEVICE LIST",
                        side: "right",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                    ],
                  ),

                  /// schematics tab with docking area
                  FusionDockableArea(
                    tabKey: "tab2",
                    showLeft: false,
                    showRight: true,
                    mainArea: const SchematicsPage(),
                    dockItemList: <DockItemConfig>[
                      DockItemConfig(
                        id: "7",
                        title: "Cost Calculator",
                        side: "right",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                      DockItemConfig(
                        id: "5",
                        title: "PRODUCT QUERY",
                        side: "right",
                        widgetBuilder: () => const ProductQuery(),
                      ),
                    ],
                  ),

                  /// budget tab with docking area
                  const FusionDockableArea(
                    tabKey: "tab3",
                    showLeft: false,
                    showRight: false,
                    mainArea: BillOfMaterialsPage(),
                    dockItemList: <DockItemConfig>[],
                  ),

                  /// Config tab without docking area
                  const FusionDockableArea(
                    tabKey: "tab4",
                    showLeft: false,
                    showRight: false,
                    mainArea: AudioSystemDesignPage(),
                    dockItemList: <DockItemConfig>[],
                  ),

                  /// Cloud tab without docking area
                  const DataTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Project Name Section
  Widget _projectNameSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      width: 237,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
        // border right
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.dividerColor, width: 1),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: "Project Name",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              FusionAppText(
                text: "File_Version",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.greyDark),
              ),
            ],
          ),

          const Icon(
            Icons.arrow_drop_down_outlined,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class DataTab extends StatelessWidget {
  const DataTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade50,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.data_usage,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              "Data Tab",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "This tab shows data without the docking workspace.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            DataCard(),
          ],
        ),
      ),
    );
  }
}

class DataCard extends StatelessWidget {
  const DataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              "Sample Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text("Users: 1,245"),
            Text("Revenue: \$45,678"),
            Text("Growth: +12.5%"),
          ],
        ),
      ),
    );
  }
}

class BarWidget extends StatelessWidget {
  final bool isExpanded;

  const BarWidget({super.key, this.isExpanded = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.bar_chart, size: 32, color: Colors.blue),
          if (isExpanded) ...<Widget>[
            const SizedBox(height: 8),
            const Text("data", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(width: 15, height: 30, color: Colors.blue),
                Container(width: 15, height: 45, color: Colors.green),
                Container(width: 15, height: 25, color: Colors.orange),
                Container(width: 15, height: 35, color: Colors.red),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// class ProjectWorkArea extends StatelessWidget {
//   // text editing controller for the email field
//   final TextEditingController emailController = TextEditingController();
//   ProjectWorkArea({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: FusionAppBar(
//           title: 'Library',
//           themeToggleWidget: ValueListenableBuilder<ThemeMode>(
//             valueListenable: FusionThemeController.themeModeNotifier,
//             builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
//               return IconButton(
//                 onPressed: () {
//                   final bool isLight = FusionThemeController.themeModeNotifier.value == ThemeMode.light;
//                   FusionThemeController.setThemeMode(
//                     isLight ? ThemeMode.dark : ThemeMode.light,
//                   );
//                 },
//                 icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
//                 tooltip: themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
//               );
//             },
//           ),
//         ),
//         body: Column(
//           children: <Widget>[
//             const TabBar(
//               tabs: <Widget>[
//                 Tab(text: 'Widgets'),
//                 Tab(text: 'Theme'),
//                 Tab(text: 'Algorithms'),
//               ],
//             ),
//             Expanded(
//               child: TabBarView(
//                 children: <Widget>[
//                   _buildWidgetsTab(context),
//                   _buildThemeTab(context),
//                   _buildAlgorithmsTab(context),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWidgetsTab(BuildContext context) {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             // Header
//             Text('Fusion Widget Library', style: Theme.of(context).textTheme.headlineMedium),
//             const SizedBox(height: 8),
//             Text('A comprehensive collection of custom Flutter widgets', style: Theme.of(context).textTheme.bodyMedium),
//             const SizedBox(height: 24),
//
//             // Text Widgets Section
//             _buildWidgetSection(
//               context,
//               title: 'Text Widgets',
//               description: 'Custom text display components with styling options',
//               children: <Widget>[
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionAppText',
//                   description: 'Basic text widget with currency formatting',
//                   widget: const FusionAppText(
//                     text: '1,250',
//                     underLine: true,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionCurrencyText',
//                   description: 'Basic text widget with currency formatting',
//                   widget: const FusionCurrencyText(
//                     text: '1,250',
//                     currencyType: CurrencyType.usd,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionAppText (Styled)',
//                   description: 'Text with custom styling',
//                   widget: const FusionAppText(
//                     text: 'Custom Styled Text',
//                     style: TextStyle(
//                       fontSize: 20,
//                       color: Colors.blue,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionGradientText',
//                   description: 'Text with gradient colors',
//                   widget: FusionGradientText(
//                     text: 'Fusion Gradient',
//                     gradient: Theme.of(context).colorScheme.gradientTextColor,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionGradientText (Currency)',
//                   description: 'Gradient text with currency formatting',
//                   widget: const FusionGradientText(
//                     text: '1,250',
//                     gradient: LinearGradient(colors: <Color>[Colors.orange, Colors.red]),
//                     fontSize: 20,
//                     isCurrency: true,
//                     underLine: true,
//                     underlineColor: Colors.redAccent,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionRichText',
//                   description: 'Rich text with inline spans',
//                   widget: const FusionRichText(
//                     text: 'Hello ',
//                     textStyle: TextStyle(fontSize: 18, color: Colors.black),
//                     inlineSpans: <InlineSpan>[
//                       TextSpan(
//                         text: 'Fusion',
//                         style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
//                       ),
//                       TextSpan(
//                         text: ' World!',
//                         style: TextStyle(color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             // Button Widgets Section
//             _buildWidgetSection(
//               context,
//               title: 'Button Widgets',
//               description: 'Interactive button components with various styles',
//               children: <Widget>[
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionButton',
//                   description: 'Primary action button with icon support',
//                   widget: FusionButton(
//                     label: 'Proceed',
//                     height: 50,
//                     width: 200,
//                     activeBackgroundColor: Theme.of(context).colorScheme.fusionButtonColor,
//                     foregroundColor: Theme.of(context).colorScheme.fusionButtonTextColor,
//                     onTap: () {},
//                     showSuffixIcon: true,
//                     suffixIcon: Icons.arrow_forward,
//                     isActive: true,
//                     isLoading: false,
//                     textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
//                       color: Theme.of(context).colorScheme.fusionButtonTextColor,
//                     ),
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionGradientButton',
//                   description: 'Button with gradient background',
//                   widget: FusionGradientButton(
//                     label: 'Continue',
//                     height: 50,
//                     width: 200,
//                     onTap: () {},
//                     foregroundColor: Theme.of(context).colorScheme.fusionButtonTextColor,
//
//                     gradient: const LinearGradient(
//                       colors: <Color>[Colors.blue, Colors.purple],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     isLoading: false,
//                     isActive: true,
//                     showSuffixIcon: true,
//                     suffixIcon: Icons.arrow_forward,
//                     textStyle: Theme.of(context).textTheme.labelLarge,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionOutlinedButton',
//                   description: 'Outlined button with prefix and suffix icons',
//                   widget: FusionOutlinedButton(
//                     label: 'Cancel',
//                     height: 50,
//                     width: 200,
//                     onTap: () {},
//                     showPrefixIcon: true,
//                     prefixIcon: Icons.close,
//                     showSuffixIcon: true,
//                     suffixIcon: Icons.arrow_forward,
//                     isActive: true,
//                     isLoading: false,
//                     foregroundColor: Theme.of(context).colorScheme.fusionOutlinedButtonColor,
//                     activeBorderColor: Theme.of(context).colorScheme.fusionOutlinedButtonColor,
//                     textStyle: Theme.of(context).textTheme.labelLarge,
//                   ),
//                 ),
//               ],
//             ),
//
//             // Form Field Widgets Section
//             _buildWidgetSection(
//               context,
//               title: 'Form Field Widgets',
//               description: 'Input components for forms and user data collection',
//               children: <Widget>[
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionTextFormField',
//                   description: 'Enhanced text form field with validation',
//                   widget: FusionTextFormField(
//                     title: 'Email',
//                     hintText: 'Enter your email',
//                     isRequired: true,
//                     onChanged: (String value) => print(value),
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionTextFormField (Password)',
//                   description: 'Password field with visibility toggle',
//                   widget: FusionTextFormField(
//                     title: 'Password',
//                     hintText: 'Enter password',
//                     isPassword: true,
//                     onChanged: (String value) => print(value),
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionTextField',
//                   description: 'Simple text input field',
//                   widget: FusionTextField(
//                     hintText: 'Enter your email',
//                     controller: emailController,
//                     keyboardType: TextInputType.emailAddress,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionDropdownButtonFormField',
//                   description: 'Dropdown selection field',
//                   widget: FusionDropdownButtonFormField(
//                     options: <String>['Option 1', 'Option 2', 'Option 3'],
//                     hintText: 'Choose option',
//                     onChanged: (String? value) {
//                       print(value);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//
//             // Toggle and Switch Widgets Section
//             _buildWidgetSection(
//               context,
//               title: 'Toggle Widgets',
//               description: 'Switch and toggle components for boolean inputs',
//               children: <Widget>[
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionToggleRow (Enabled)',
//                   description: 'Toggle switch with label',
//                   widget: FusionToggleRow(
//                     title: "Enable Notifications",
//                     value: true,
//                     onChanged: (bool newValue) {
//                       print("Switch is now: $newValue");
//                     },
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionToggleRow (Disabled)',
//                   description: 'Toggle switch in disabled state',
//                   widget: FusionToggleRow(
//                     title: "Dark Mode",
//                     value: false,
//                     onChanged: (bool newValue) {
//                       print("Dark Mode is now: $newValue");
//                     },
//                   ),
//                 ),
//               ],
//             ),
//
//             // Other Widgets Section
//             _buildWidgetSection(
//               context,
//               title: 'Other Widgets',
//               description: 'Miscellaneous UI components',
//               children: <Widget>[
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionProfileImage (Network)',
//                   description: 'Profile image from URL',
//                   widget: const FusionProfileImage(
//                     imageUrl: "https://www.shutterstock.com/image-vector/black-dog-head-icon-silhouette-600nw-2575215237.jpg",
//                     size: 80,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionProfileImage (Placeholder)',
//                   description: 'Profile image placeholder',
//                   widget: const FusionProfileImage(
//                     size: 60,
//                   ),
//                 ),
//                 _buildWidgetItem(
//                   context,
//                   name: 'FusionShimmer',
//                   description: 'Loading shimmer effect',
//                   widget: const FusionShimmer(
//                     width: 120,
//                     height: 20,
//                     radius: 8,
//                   ),
//                 ),
//               ],
//             ),
//
//             // Theme Toggle Section
//             _buildWidgetSection(
//               context,
//               title: 'Theme Controls',
//               description: 'Theme switching functionality',
//               children: <Widget>[
//                 _buildWidgetItem(
//                   context,
//                   name: 'Theme Toggle Button',
//                   description: 'Standard elevated button for theme switching',
//                   widget: ElevatedButton(
//                     style: Theme.of(context).elevatedButtonTheme.style,
//                     onPressed: () {
//                       final bool isLight = FusionThemeController.themeModeNotifier.value == ThemeMode.light;
//                       FusionThemeController.setThemeMode(
//                         isLight ? ThemeMode.dark : ThemeMode.light,
//                       );
//                       print('Theme toggled to ${isLight ? 'Dark' : 'Light'} mode');
//                     },
//                     child: const Text('Toggle Theme'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWidgetSection(
//     BuildContext context, {
//     required String title,
//     required String description,
//     required List<Widget> children,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 32),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           // Section Header
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                   color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Widgets
//           ...children,
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWidgetItem(
//     BuildContext context, {
//     required String name,
//     required String description,
//     required Widget widget,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
//         ),
//         boxShadow: <BoxShadow>[
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           // Widget Info
//           Row(
//             children: <Widget>[
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Text(
//                       name,
//                       style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         color: Theme.of(context).colorScheme.onSurface,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       description,
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Widget Preview
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surface,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
//               ),
//             ),
//             child: Center(child: widget),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Dynamically generates color palette from ColorExtends extension
//   List<Map<String, dynamic>> _getDynamicColorPalette(ColorScheme colorScheme) {
//     return <Map<String, dynamic>>[
//       <String, dynamic>{
//         'name': 'Primary Color',
//         'color': colorScheme.primaryColor,
//         'getter': 'primaryColor',
//       },
//       <String, dynamic>{
//         'name': 'Fusion Button Color',
//         'color': colorScheme.fusionButtonColor,
//         'getter': 'fusionButtonColor',
//       },
//       <String, dynamic>{
//         'name': 'Fusion Button Text',
//         'color': colorScheme.fusionButtonTextColor,
//         'getter': 'fusionButtonTextColor',
//       },
//       <String, dynamic>{
//         'name': 'Fusion Text View',
//         'color': colorScheme.fusionTextViewColor,
//         'getter': 'fusionTextViewColor',
//       },
//       <String, dynamic>{
//         'name': 'Fusion Outlined Button',
//         'color': colorScheme.fusionOutlinedButtonColor,
//         'getter': 'fusionOutlinedButtonColor',
//       },
//       <String, dynamic>{
//         'name': 'Launcher Background 1',
//         'color': colorScheme.launcherBgColor1,
//         'getter': 'launcherBgColor1',
//       },
//       <String, dynamic>{
//         'name': 'Launcher Background 2',
//         'color': colorScheme.launcherBgColor2,
//         'getter': 'launcherBgColor2',
//       },
//       <String, dynamic>{
//         'name': 'Grey Dark',
//         'color': colorScheme.greyDark,
//         'getter': 'greyDark',
//       },
//       <String, dynamic>{
//         'name': 'Soft Grey',
//         'color': colorScheme.softGrey,
//         'getter': 'softGrey',
//       },
//       <String, dynamic>{
//         'name': 'Grey',
//         'color': colorScheme.grey,
//         'getter': 'grey',
//       },
//       <String, dynamic>{
//         'name': 'Grey Light',
//         'color': colorScheme.greyLight,
//         'getter': 'greyLight',
//       },
//       <String, dynamic>{
//         'name': 'White',
//         'color': colorScheme.white,
//         'getter': 'white',
//       },
//       <String, dynamic>{
//         'name': 'Black',
//         'color': colorScheme.black,
//         'getter': 'black',
//       },
//       <String, dynamic>{
//         'name': 'Border Color',
//         'color': colorScheme.textFieldBorderColor,
//         'getter': 'borderColorL',
//       },
//       <String, dynamic>{
//         'name': 'Black Transparent',
//         'color': colorScheme.blackTransparentL,
//         'getter': 'blackTransparentL',
//       },
//     ].map((Map<String, dynamic> item) {
//       // Add hex value dynamically
//       final Color color = item['color'] as Color;
//       item['value'] = '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
//       return item;
//     }).toList();
//   }
//
//   Widget _buildThemeTab(BuildContext context) {
//     final ColorScheme colorScheme = Theme.of(context).colorScheme;
//     final TextTheme textTheme = Theme.of(context).textTheme;
//
//     // Use dynamic color palette
//     final List<Map<String, dynamic>> colorPalette = _getDynamicColorPalette(colorScheme);
//
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: <Widget>[
//           Text(
//             'Theme Palette',
//             style: textTheme.headlineMedium?.copyWith(
//               color: colorScheme.fusionTextViewColor,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Current theme: ${colorScheme.isDarkMode ? 'Dark Mode' : 'Light Mode'}',
//             style: textTheme.bodyLarge?.copyWith(
//               color: colorScheme.greyDark,
//             ),
//           ),
//           Text(
//             'Total colors: ${colorPalette.length}',
//             style: textTheme.bodyMedium?.copyWith(
//               color: colorScheme.greyDark,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Wrap(
//             spacing: 12,
//             runSpacing: 12,
//             children:
//                 colorPalette.map((Map<String, dynamic> colorInfo) {
//                   return Container(
//                     width: (MediaQuery.of(context).size.width - 56) / 2,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).cardColor,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: colorScheme.greyDark.withOpacity(0.2),
//                       ),
//                     ),
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       children: <Widget>[
//                         // Color container
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: colorInfo['color'],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(
//                               color: colorScheme.greyDark.withOpacity(0.3),
//                               width: 1,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         // Color info
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: <Widget>[
//                               Text(
//                                 colorInfo['name'],
//                                 style: textTheme.labelLarge?.copyWith(
//                                   color: colorScheme.fusionTextViewColor,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 colorInfo['value'],
//                                 style: textTheme.bodySmall?.copyWith(
//                                   color: colorScheme.greyDark,
//                                   fontFamily: 'monospace',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAlgorithmsTab(BuildContext context) {
//     return const DefaultTabController(
//       length: 5,
//       child: Column(
//         children: <Widget>[
//           TabBar(
//             tabs: <Widget>[
//               Tab(text: 'SPL Calculation'),
//               Tab(text: 'Tap Setting'),
//               Tab(text: 'Circuiting'),
//               Tab(text: 'Amp Matching'),
//               Tab(text: 'Device Recommender'),
//             ],
//           ),
//           Expanded(
//             child: TabBarView(
//               children: <Widget>[
//                 SplCalculationWidget(),
//                 TapSettingWidget(),
//                 CircuitingWidget(),
//                 AmplifierMatchingWidget(),
//                 DeviceRecommenderWidget(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
