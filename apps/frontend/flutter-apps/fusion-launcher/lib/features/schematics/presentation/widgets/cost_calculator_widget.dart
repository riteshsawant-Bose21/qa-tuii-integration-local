import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/fusion_models.dart';

class CostCalculatorScreen extends StatefulWidget {
  final List<Speaker> speakers;
  final List<Source> sources;
  final List<HardwareComponent> controllers;
  final List<HardwareComponent> racks;
  final List<Amplifier> amplifiers;
  final List<FusionDsp> fusionDevices;
  final List<HardwareComponent> others;

  const CostCalculatorScreen({
    super.key,
    required this.speakers,
    required this.sources,
    required this.controllers,
    required this.racks,
    required this.amplifiers,
    required this.fusionDevices,
    required this.others,
  });

  static const Color primaryText = Color(0xCC000000);
  static const Color secondaryText = Color(0x4D000000);
  static const Color accentColor = Color(0xFF146C94);
  static const double fsSmall = 11;
  static const double fsRegular = 12;
  static const double fsMedium = 13;

  @override
  State<CostCalculatorScreen> createState() => _CostCalculatorScreenState();
}

class _CostCalculatorScreenState extends State<CostCalculatorScreen> with TickerProviderStateMixin {
  // Individual animation controllers for each section
  late final Map<String, AnimationController> _rotationControllers = <String, AnimationController>{};
  late final Map<String, Animation<double>> _rotationAnimations = <String, Animation<double>>{};

  // Track expansion state for each section (default to expanded)
  final Map<String, bool> _expansionStates = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
  }

  void _initializeAnimationControllers() {
    final List<String> sections = <String>['Loudspeakers', 'Sources', 'Controllers', 'Racks', 'Others'];

    for (String section in sections) {
      // Start with expanded state (value: 1.0 means rotated/expanded)
      _rotationControllers[section] = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: 1.0);

      _rotationAnimations[section] = Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).animate(CurvedAnimation(parent: _rotationControllers[section]!, curve: Curves.easeInOut));

      // Set default expansion state to true (expanded)
      _expansionStates[section] = true;
    }
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (AnimationController controller in _rotationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Handles expansion state changes for a specific section
  void _handleExpansionChanged(String section, bool expanded) {
    _expansionStates[section] = expanded;

    if (expanded) {
      _rotationControllers[section]?.forward();
    } else {
      _rotationControllers[section]?.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = _calculateTotalItems();
    final double totalCost = _calculateTotalCost();

    return Container(
      padding: const EdgeInsets.only(top: 0, bottom: 16, left: 16, right: 16),
      child: Column(
        children: <Widget>[
          /// Component Sections
          _buildHardwareSection("Loudspeakers", widget.speakers, Icons.speaker_outlined),
          _buildHardwareSection("Sources", widget.sources, Icons.input_outlined),
          _buildHardwareSection("Controllers", widget.controllers, Icons.settings_remote_outlined),
          _buildHardwareSection("Racks", widget.racks, Icons.dns_outlined),
          _buildComponentSection("Amplifiers", widget.amplifiers, Icons.graphic_eq_outlined),
          _buildComponentSection("Fusion Devices", widget.fusionDevices, Icons.hub_outlined),
          _buildHardwareSection("Others", widget.others, Icons.widgets_outlined),

          const SizedBox(
            height: 6,
          ),

          /// Total Section
          Row(
            children: <Widget>[
              FusionAppText(
                text: "Total Cost",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FusionAppText(
                text: totalItems.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 28),
              FusionAppText(
                text: '\$${totalCost.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSection<T>(String title, List<T> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 0,
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        collapsedIconColor: CostCalculatorScreen.primaryText,
        iconColor: CostCalculatorScreen.accentColor,
        title: Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(text:
                title,
                style: const TextStyle(
                  fontSize: CostCalculatorScreen.fsRegular,
                  color: CostCalculatorScreen.primaryText,
                ),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.centerRight,
              child: FusionAppText(text:
                items.length.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: CostCalculatorScreen.fsSmall,
                  color: CostCalculatorScreen.primaryText,
                ),
              ),
            ),
            Container(
              width: 70,
              alignment: Alignment.centerRight,
              child: FusionAppText(text:
                '\$${items.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: CostCalculatorScreen.fsRegular,
                  color: CostCalculatorScreen.primaryText,
                ),
              ),
            ),
          ],
        ),

        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: items.map((dynamic item) => _buildItemRow(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareSection(String title, List<HardwareComponent> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    final Map<String, List<HardwareComponent>> groupedItems = _groupHardwareComponentsBySku(items);

    return SemanticHelper.toggle(
      testId: SemanticHelper.createTestId(SemanticTypes.toggle, "${title}_cost_calculator"),
      value: _expansionStates[title] ?? true,
      child: ExpansionTile(
        childrenPadding: EdgeInsets.zero,
        minTileHeight: 0,
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        collapsedIconColor: CostCalculatorScreen.primaryText,
        iconColor: CostCalculatorScreen.accentColor,
        onExpansionChanged: (bool expanded) => _handleExpansionChanged(title, expanded),
        tilePadding: EdgeInsets.zero,
        showTrailingIcon: false, // Hide default trailing icon since we're using custom one
        initiallyExpanded: true, // Start expanded by default
        title: Row(
          children: <Widget>[
            _RotatingIcon(animation: _rotationAnimations[title] ?? _rotationAnimations.values.first, color: Theme.of(context).colorScheme.fusionButtonColor),
            const SizedBox(width: 4),
            Expanded(
              child: FusionAppText(
                text: title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              alignment: Alignment.centerRight,
              child: FusionAppText(
                text: items.length.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
            Container(
              width: 70,
              color: Colors.red,
              alignment: Alignment.centerRight,
              child: FusionAppText(
                maxLine: 1,
                text: '\$${items.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Column(
              children: groupedItems.entries.map((MapEntry<String, List<HardwareComponent>> entry) => _buildHardwareItemRow(entry.key, entry.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 0, right: 8),
            decoration: BoxDecoration(
              color: CostCalculatorScreen.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: FusionAppText(text:
              _getItemName(item),
              style: const TextStyle(
                fontSize: CostCalculatorScreen.fsSmall,
                color: CostCalculatorScreen.primaryText,
              ),
            ),
          ),

          Container(
            width: 70,
            alignment: Alignment.centerRight,
            child: FusionAppText(text:
              '\$${_getItemPrice(item).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: CostCalculatorScreen.fsSmall,
                color: CostCalculatorScreen.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareItemRow(String sku, List<HardwareComponent> items) {
    final int quantity = items.length;
    final double totalPrice = items.fold(0.0, (double sum, HardwareComponent item) => sum + item.price);
    final HardwareComponent sampleItem = items.first;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 0, right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: FusionAppText(
              text: _getItemName(sampleItem),
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.centerRight,
            child: FusionAppText(
              text: 'x$quantity',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ),
          Container(
            width: 70,
            alignment: Alignment.centerRight,
            child: FusionAppText(
              text: '\$${totalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<HardwareComponent>> _groupHardwareComponentsBySku(List<HardwareComponent> items) {
    final Map<String, List<HardwareComponent>> grouped = <String, List<HardwareComponent>>{};
    for (HardwareComponent item in items) {
      final String sku = _getItemSku(item) ?? 'Unknown';
      grouped.putIfAbsent(sku, () => <HardwareComponent>[]).add(item);
    }
    return grouped;
  }

  String _getItemName(dynamic item) {
    if (item is Speaker) return item.name ?? 'Unknown Speaker';
    if (item is Source) return item.name ?? 'Unknown Source';
    if (item is HardwareComponent) return item.name ?? 'Unknown Component';
    if (item is Amplifier) return item.name ?? 'Unknown Amplifier';
    if (item is FusionDsp) return item.name ?? 'Unknown Fusion Device';
    return 'Unknown Item';
  }

  String? _getItemSku(dynamic item) {
    if (item is Speaker) return item.speakerSKU;
    if (item is Source) return item.sku;
    if (item is HardwareComponent) return item.hardwareName;
    if (item is Amplifier) return item.name;
    if (item is FusionDsp) return item.name;
    return null;
  }

  double _getItemPrice(dynamic item) {
    if (item is Speaker) return item.price;
    if (item is Source) return item.price;
    if (item is HardwareComponent) return item.price;
    if (item is Amplifier) return item.price;
    if (item is FusionDsp) return item.price;
    return 0.0;
  }

  int _calculateTotalItems() {
    return widget.speakers.length +
        widget.sources.length +
        widget.controllers.length +
        widget.racks.length +
        widget.amplifiers.length +
        widget.fusionDevices.length +
        widget.others.length;
  }

  double _calculateTotalCost() {
    return widget.speakers.totalPrice +
        widget.sources.totalPrice +
        widget.controllers.totalPrice +
        widget.racks.totalPrice +
        widget.amplifiers.totalPrice +
        widget.fusionDevices.totalPrice +
        widget.others.totalPrice;
  }
}

// Extension method for calculating total price
extension ListExtensions<T> on List<T> {
  double get totalPrice {
    return fold(0.0, (double sum, dynamic item) {
      if (item is Speaker) return sum + item.price;
      if (item is Source) return sum + item.price;
      if (item is HardwareComponent) return sum + item.price;
      if (item is Amplifier) return sum + item.price;
      if (item is FusionDsp) return sum + item.price;
      return sum;
    });
  }
}

/// A rotating icon widget that animates based on expansion state.
///
/// Displays a downward-pointing arrow icon that rotates 180 degrees during
/// the expand/collapse animation to provide visual feedback to users.
/// The icon points down when collapsed and up when expanded.
class _RotatingIcon extends StatelessWidget {
  const _RotatingIcon({required this.animation, required this.color});

  /// The animation that drives the rotation transformation.
  ///
  /// Should be a value between 0.0 (no rotation) and 0.5 (180 degrees).
  final Animation<double> animation;

  /// The color to apply to the icon.
  ///
  /// Should match the theme's text color for consistency.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder:
          (BuildContext context, Widget? child) => RotationTransition(
            turns: animation,
            child: Icon(Icons.keyboard_arrow_down, size: 16, color: color),
          ),
    );
  }
}
