import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/bill_of_materials/state/bom_state.dart';
import 'package:fusion_launcher/features/bill_of_materials/viewmodel/bom_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

/// Cost calculator that reads from [BomViewModel] so prices and data
/// are always consistent with the BOM page (uses product-catalog prices,
/// excludes sources).
class CostCalculatorScreen extends StatelessWidget {
  const CostCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BomViewModel>(
      create: (_) => BomViewModel(),
      child: BlocBuilder<BomViewModel, BomState>(
        builder: (BuildContext context, BomState state) {
          return _CostCalculatorBody(items: state.allItems);
        },
      ),
    );
  }
}

class _CostCalculatorBody extends StatefulWidget {
  const _CostCalculatorBody({required this.items});
  final List<BomItem> items;

  @override
  State<_CostCalculatorBody> createState() => _CostCalculatorBodyState();
}

class _CostCalculatorBodyState extends State<_CostCalculatorBody> with TickerProviderStateMixin {
  static const double _fsSmall = 11;
  static const double _fsRegular = 12;

  // Fixed column widths — shared between header rows and item rows.
  static const double _colQty = 32.0;
  static const double _colPrice = 76.0;

  // Categories to display (sources and racks excluded)
  static const List<String> _categories = <String>[
    'Loud Speaker',
    'Amplifier',
    'Processor',
    'Controller',
    'Endpoint',
    'Network Switch',
    'Other',
  ];

  static const Map<String, String> _categoryLabels = <String, String>{
    'Loud Speaker': 'Loudspeakers',
    'Amplifier': 'Amplifiers',
    'Processor': 'Processors / DSPs',
    'Controller': 'Controllers',
    'Endpoint': 'Endpoints',
    'Network Switch': 'Network Switches',
    'Other': 'Others',
  };

  late final Map<String, AnimationController> _controllers;
  late final Map<String, Animation<double>> _animations;
  final Map<String, bool> _expanded = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _controllers = <String, AnimationController>{};
    _animations = <String, Animation<double>>{};
    for (final String cat in _categories) {
      _controllers[cat] = AnimationController(duration: const Duration(milliseconds: 200), vsync: this, value: 1.0);
      _animations[cat] = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _controllers[cat]!, curve: Curves.easeInOut),
      );
      _expanded[cat] = true;
    }
  }

  @override
  void dispose() {
    for (final AnimationController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Only items in the displayed categories (excludes sources and racks).
  List<BomItem> get _visibleItems => widget.items.where((BomItem i) => _categories.contains(i.type)).toList();

  List<BomItem> _itemsForCategory(String type) => widget.items.where((BomItem i) => i.type == type).toList();

  double _totalCost() => _visibleItems.fold(0.0, (double s, BomItem i) => s + i.unitPrice * i.quantity);

  int _totalCount() => _visibleItems.fold(0, (int s, BomItem i) => s + i.quantity);

  void _onExpansionChanged(String cat, bool expanded) {
    setState(() => _expanded[cat] = expanded);
    expanded ? _controllers[cat]?.forward() : _controllers[cat]?.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Column(
        children: <Widget>[
          for (final String cat in _categories) _buildSection(cat),
          const SizedBox(height: 6),
          // ── Total row ──
          Row(
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: 'Total Cost',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: _colQty,
                child: FusionAppText(
                  text: _totalCount().toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: _colPrice,
                child: FusionAppText(
                  text: '\$${_totalCost().toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String type) {
    final List<BomItem> items = _itemsForCategory(type);
    if (items.isEmpty) return const SizedBox.shrink();

    final String label = _categoryLabels[type] ?? type;
    final double sectionTotal = items.fold(0.0, (double s, BomItem i) => s + i.unitPrice * i.quantity);
    final int sectionCount = items.fold(0, (int s, BomItem i) => s + i.quantity);

    return SemanticHelper.toggle(
      testId: SemanticHelper.createTestId(SemanticTypes.toggle, '${label}_cost_calculator'),
      value: _expanded[type] ?? true,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          childrenPadding: EdgeInsets.zero,
          minTileHeight: 0,
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          onExpansionChanged: (bool v) => _onExpansionChanged(type, v),
          tilePadding: EdgeInsets.zero,
          showTrailingIcon: false,
          initiallyExpanded: true,
          title: Row(
            children: <Widget>[
              _RotatingIcon(
                animation: _animations[type] ?? _animations.values.first,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FusionAppText(
                  text: label,
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: _fsSmall),
                ),
              ),
              // Quantity count
              SizedBox(
                width: _colQty,
                child: FusionAppText(
                  text: sectionCount.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: _fsSmall),
                ),
              ),
              // Section total price
              SizedBox(
                width: _colPrice,
                child: FusionAppText(
                  maxLine: 1,
                  text: '\$${sectionTotal.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: _fsRegular),
                ),
              ),
            ],
          ),
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Column(
                children: items.map((BomItem item) => _buildItemRow(item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(BomItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: FusionAppText(
              text: item.name,
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: _fsSmall, color: context.colorScheme.textSecondary),
            ),
          ),
          SizedBox(
            width: _colQty,
            child: FusionAppText(
              text: 'x${item.quantity}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: _fsSmall, color: context.colorScheme.textSecondary),
            ),
          ),
          SizedBox(
            width: _colPrice,
            child: FusionAppText(
              text: '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: _fsSmall, color: context.colorScheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatingIcon extends StatelessWidget {
  const _RotatingIcon({required this.animation, required this.color});
  final Animation<double> animation;
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
