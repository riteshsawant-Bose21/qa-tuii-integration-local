import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/fusion_theme_notifier.dart';
import 'package:fusion_lib/fusion_widgets/appbar/fusion_app_bar.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_gradient_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_drop_down_button_form_field.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_form_field.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_toggle_switch.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_profile_image.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_shimmer.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_currency_text.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_gradient_text.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_rich_text.dart';

import '../../features/dashboard/presentation/widgets/algorithms/amplifier_matching_widget.dart';
import '../../features/dashboard/presentation/widgets/algorithms/circuiting_widget.dart';
import '../../features/dashboard/presentation/widgets/algorithms/device_recommender_widget.dart';
import '../../features/dashboard/presentation/widgets/algorithms/spl_calculation_widget.dart';
import '../../features/dashboard/presentation/widgets/algorithms/tap_setting_widget.dart';
import '../../features/dashboard/presentation/widgets/products_filter/product_filter.dart';

class TestLibraryScreen extends StatelessWidget {
  // text editing controller for the email field
  final TextEditingController emailController = TextEditingController();
  TestLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: FusionAppBar(
          title: const Text('Library'),
          themeToggleWidget: ValueListenableBuilder<ThemeMode>(
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
        ),
        body: Column(
          children: <Widget>[
            const TabBar(
              tabs: <Widget>[
                Tab(text: 'Widgets'),
                Tab(text: 'Theme'),
                Tab(text: 'Algorithms'),
                Tab(text: 'Products'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _buildWidgetsTab(context),
                  _buildThemeTab(context),
                  _buildAlgorithmsTab(context),
                  _buildProductsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetsTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Text('Fusion Widget Library', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('A comprehensive collection of custom Flutter widgets', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Text Widgets Section
            _buildWidgetSection(
              context,
              title: 'Text Widgets',
              description: 'Custom text display components with styling options',
              children: <Widget>[
                _buildWidgetItem(
                  context,
                  name: 'FusionAppText',
                  description: 'Basic text widget with currency formatting',
                  widget: const FusionAppText(
                    text: '1,250',
                    underLine: true,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionCurrencyText',
                  description: 'Basic text widget with currency formatting',
                  widget: const FusionCurrencyText(
                    text: '1,250',
                    currencyType: CurrencyType.usd,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionAppText (Styled)',
                  description: 'Text with custom styling',
                  widget: const FusionAppText(
                    text: 'Custom Styled Text',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionGradientText',
                  description: 'Text with gradient colors',
                  widget: FusionGradientText(
                    text: 'Fusion Gradient',
                    gradient: Theme.of(context).colorScheme.gradientTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionGradientText (Currency)',
                  description: 'Gradient text with currency formatting',
                  widget: const FusionGradientText(
                    text: '1,250',
                    gradient: LinearGradient(colors: <Color>[Colors.orange, Colors.red]),
                    fontSize: 20,
                    isCurrency: true,
                    underLine: true,
                    underlineColor: Colors.redAccent,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionRichText',
                  description: 'Rich text with inline spans',
                  widget: const FusionRichText(
                    text: 'Hello ',
                    textStyle: TextStyle(fontSize: 18, color: Colors.black),
                    inlineSpans: <InlineSpan>[
                      TextSpan(
                        text: 'Fusion',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' World!',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Button Widgets Section
            _buildWidgetSection(
              context,
              title: 'Button Widgets',
              description: 'Interactive button components with various styles',
              children: <Widget>[
                _buildWidgetItem(
                  context,
                  name: 'FusionButton',
                  description: 'Primary action button with icon support',
                  widget: FusionButton(
                    label: 'Proceed',
                    height: 50,
                    width: 200,
                    activeBackgroundColor: Theme.of(context).colorScheme.fusionButtonColor,
                    foregroundColor: Theme.of(context).colorScheme.fusionButtonTextColor,
                    onTap: () {},
                    showSuffixIcon: true,
                    suffixIcon: Icons.arrow_forward,
                    isActive: true,
                    isLoading: false,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.fusionButtonTextColor,
                    ),
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionGradientButton',
                  description: 'Button with gradient background',
                  widget: FusionGradientButton(
                    label: 'Continue',
                    height: 50,
                    width: 200,
                    onTap: () {},
                    foregroundColor: Theme.of(context).colorScheme.fusionButtonTextColor,

                    gradient: const LinearGradient(
                      colors: <Color>[Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    isLoading: false,
                    isActive: true,
                    showSuffixIcon: true,
                    suffixIcon: Icons.arrow_forward,
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionOutlinedButton',
                  description: 'Outlined button with prefix and suffix icons',
                  widget: FusionOutlinedButton(
                    label: 'Cancel',
                    height: 50,
                    width: 200,
                    onTap: () {},
                    showPrefixIcon: true,
                    prefixIcon: Icons.close,
                    showSuffixIcon: true,
                    suffixIcon: Icons.arrow_forward,
                    isActive: true,
                    isLoading: false,
                    foregroundColor: Theme.of(context).colorScheme.fusionOutlinedButtonColor,
                    activeBorderColor: Theme.of(context).colorScheme.fusionOutlinedButtonColor,
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),

            // Form Field Widgets Section
            _buildWidgetSection(
              context,
              title: 'Form Field Widgets',
              description: 'Input components for forms and user data collection',
              children: <Widget>[
                _buildWidgetItem(
                  context,
                  name: 'FusionTextFormField',
                  description: 'Enhanced text form field with validation',
                  widget: FusionTextFormField(
                    title: 'Email',
                    hintText: 'Enter your email',
                    isRequired: true,
                    onChanged: (String value) => debugPrint(value),
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionTextFormField (Password)',
                  description: 'Password field with visibility toggle',
                  widget: FusionTextFormField(
                    title: 'Password',
                    hintText: 'Enter password',
                    isPassword: true,
                    onChanged: (String value) => debugPrint(value),
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionTextField',
                  description: 'Simple text input field',
                  widget: FusionTextField(
                    hintText: 'Enter your email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionDropdownButtonFormField',
                  description: 'Dropdown selection field',
                  widget: FusionDropdownButtonFormField(
                    options: <String>['Option 1', 'Option 2', 'Option 3'],
                    hintText: 'Choose option',
                    onChanged: (String? value) {
                      debugPrint(value);
                    },
                  ),
                ),
              ],
            ),

            // Toggle and Switch Widgets Section
            _buildWidgetSection(
              context,
              title: 'Toggle Widgets',
              description: 'Switch and toggle components for boolean inputs',
              children: <Widget>[
                _buildWidgetItem(
                  context,
                  name: 'FusionToggleRow (Enabled)',
                  description: 'Toggle switch with label',
                  widget: FusionToggleRow(
                    title: "Enable Notifications",
                    value: true,
                    onChanged: (bool newValue) {
                      debugPrint("Switch is now: $newValue");
                    },
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionToggleRow (Disabled)',
                  description: 'Toggle switch in disabled state',
                  widget: FusionToggleRow(
                    title: "Dark Mode",
                    value: false,
                    onChanged: (bool newValue) {
                      debugPrint("Dark Mode is now: $newValue");
                    },
                  ),
                ),
              ],
            ),

            // Other Widgets Section
            _buildWidgetSection(
              context,
              title: 'Other Widgets',
              description: 'Miscellaneous UI components',
              children: <Widget>[
                _buildWidgetItem(
                  context,
                  name: 'FusionProfileImage (Network)',
                  description: 'Profile image from URL',
                  widget: const FusionProfileImage(
                    imageUrl: "https://www.shutterstock.com/image-vector/black-dog-head-icon-silhouette-600nw-2575215237.jpg",
                    size: 80,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionProfileImage (Placeholder)',
                  description: 'Profile image placeholder',
                  widget: const FusionProfileImage(
                    size: 60,
                  ),
                ),
                _buildWidgetItem(
                  context,
                  name: 'FusionShimmer',
                  description: 'Loading shimmer effect',
                  widget: const FusionShimmer(
                    width: 120,
                    height: 20,
                    radius: 8,
                  ),
                ),
              ],
            ),

            // Theme Toggle Section
            _buildWidgetSection(
              context,
              title: 'Theme Controls',
              description: 'Theme switching functionality',
              children: <Widget>[
                _buildWidgetItem(
                  context,
                  name: 'Theme Toggle Button',
                  description: 'Standard elevated button for theme switching',
                  widget: ElevatedButton(
                    style: Theme.of(context).elevatedButtonTheme.style,
                    onPressed: () {
                      final bool isLight = FusionThemeController.themeModeNotifier.value == ThemeMode.light;
                      FusionThemeController.setThemeMode(
                        isLight ? ThemeMode.dark : ThemeMode.light,
                      );
                      debugPrint('Theme toggled to ${isLight ? 'Dark' : 'Light'} mode');
                    },
                    child: const Text('Toggle Theme'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Section Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Widgets
          ...children,
        ],
      ),
    );
  }

  Widget _buildWidgetItem(
    BuildContext context, {
    required String name,
    required String description,
    required Widget widget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Widget Info
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Widget Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Center(child: widget),
          ),
        ],
      ),
    );
  }

  /// Dynamically generates color palette from ColorExtends extension
  List<Map<String, dynamic>> _getDynamicColorPalette(ColorScheme colorScheme) {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Primary Color',
        'color': colorScheme.primaryColor,
        'getter': 'primaryColor',
      },
      <String, dynamic>{
        'name': 'Fusion Button Color',
        'color': colorScheme.fusionButtonColor,
        'getter': 'fusionButtonColor',
      },
      <String, dynamic>{
        'name': 'Fusion Button Text',
        'color': colorScheme.fusionButtonTextColor,
        'getter': 'fusionButtonTextColor',
      },
      <String, dynamic>{
        'name': 'Fusion Text View',
        'color': colorScheme.fusionTextViewColor,
        'getter': 'fusionTextViewColor',
      },
      <String, dynamic>{
        'name': 'Fusion Outlined Button',
        'color': colorScheme.fusionOutlinedButtonColor,
        'getter': 'fusionOutlinedButtonColor',
      },
      <String, dynamic>{
        'name': 'Launcher Background 1',
        'color': colorScheme.launcherBgColor1,
        'getter': 'launcherBgColor1',
      },
      <String, dynamic>{
        'name': 'Launcher Background 2',
        'color': colorScheme.launcherBgColor2,
        'getter': 'launcherBgColor2',
      },
      <String, dynamic>{
        'name': 'Grey Dark',
        'color': colorScheme.greyDark,
        'getter': 'greyDark',
      },
      <String, dynamic>{
        'name': 'Soft Grey',
        'color': colorScheme.softGrey,
        'getter': 'softGrey',
      },
      <String, dynamic>{
        'name': 'Grey',
        'color': colorScheme.grey,
        'getter': 'grey',
      },
      <String, dynamic>{
        'name': 'Grey Light',
        'color': colorScheme.greyLight,
        'getter': 'greyLight',
      },
      <String, dynamic>{
        'name': 'White',
        'color': colorScheme.white,
        'getter': 'white',
      },
      <String, dynamic>{
        'name': 'Black',
        'color': colorScheme.black,
        'getter': 'black',
      },
      <String, dynamic>{
        'name': 'Border Color',
        'color': colorScheme.textFieldBorderColor,
        'getter': 'borderColorL',
      },
      <String, dynamic>{
        'name': 'Black Transparent',
        'color': colorScheme.blackTransparentL,
        'getter': 'blackTransparentL',
      },
    ].map((Map<String, dynamic> item) {
      // Add hex value dynamically
      final Color color = item['color'] as Color;
      item['value'] = '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
      return item;
    }).toList();
  }

  Widget _buildThemeTab(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Use dynamic color palette
    final List<Map<String, dynamic>> colorPalette = _getDynamicColorPalette(colorScheme);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Theme Palette',
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.fusionTextViewColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current theme: ${colorScheme.isDarkMode ? 'Dark Mode' : 'Light Mode'}',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.greyDark,
            ),
          ),
          Text(
            'Total colors: ${colorPalette.length}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.greyDark,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                colorPalette.map((Map<String, dynamic> colorInfo) {
                  return Container(
                    width: (MediaQuery.of(context).size.width - 56) / 2,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.greyDark.withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        // Color container
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorInfo['color'],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.greyDark.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Color info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                colorInfo['name'],
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.fusionTextViewColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                colorInfo['value'],
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.greyDark,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmsTab(BuildContext context) {
    return const DefaultTabController(
      length: 5,
      child: Column(
        children: <Widget>[
          TabBar(
            tabs: <Widget>[
              Tab(text: 'SPL Calculation'),
              Tab(text: 'Tap Setting'),
              Tab(text: 'Circuiting'),
              Tab(text: 'Amp Matching'),
              Tab(text: 'Device Recommender'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                SplCalculationWidget(),
                TapSettingWidget(),
                CircuitingWidget(),
                AmplifierMatchingWidget(),
                DeviceRecommenderWidget(),
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
