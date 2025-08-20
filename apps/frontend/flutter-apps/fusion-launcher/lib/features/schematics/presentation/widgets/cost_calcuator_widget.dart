import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/models/amplifer.dart';
import 'package:fusion_launcher/core/models/fusion_device.dart';
import 'package:fusion_launcher/core/models/hardware_component_entity.dart';

import '../../../../core/models/source_entity.dart';
import '../../../../core/models/speaker_entity.dart';

class CostCalculatorScreen extends StatelessWidget {
  final List<Speaker> speakers;
  final List<Source> sources;
  final List<HardwareComponent> controllers;
  final List<HardwareComponent> racks;
  final List<Amplifier> amplifiers;
  final List<FusionDevice> fusionDevices;
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
  Widget build(BuildContext context) {
    return _buildCostCalculator(context);
  }

  Widget _buildCostCalculator(BuildContext context) {
    final int totalItems = _calculateTotalItems();
    final double totalCost = _calculateTotalCost();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1, color: Color(0xFFD5D5D5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(
                      Icons.calculate_outlined,
                      color: accentColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'COST CALCULATOR',
                      style: TextStyle(
                        fontSize: fsSmall,
                        color: primaryText,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              children: <Widget>[
                // Component Sections
                _buildHardwareSection("Speakers", speakers, Icons.speaker_outlined),
                _buildHardwareSection("Sources", sources, Icons.input_outlined),
                _buildHardwareSection("Controllers", controllers, Icons.settings_remote_outlined),
                _buildHardwareSection("Racks", racks, Icons.dns_outlined),
                _buildComponentSection("Amplifiers", amplifiers, Icons.graphic_eq_outlined),
                _buildComponentSection("Fusion Devices", fusionDevices, Icons.hub_outlined),
                _buildHardwareSection("Others", others, Icons.widgets_outlined),

                // Total Section
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: fsMedium,
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            totalItems.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: fsSmall,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '\$${totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: fsMedium,
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSection<T>(String title, List<T> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      childrenPadding: EdgeInsets.zero,
      minTileHeight: 0,
      collapsedBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      collapsedIconColor: primaryText,
      iconColor: accentColor,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Icon(icon, size: 16, color: const Color(0xFF464545)),
            // const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: fsRegular,
                color: primaryText,
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                items.length.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: fsSmall,
                  color: primaryText,
                ),
              ),
            ),

            Text(
              '\$${items.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: fsRegular,
                color: primaryText,
              ),
            ),
          ],
        ),
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
    );
  }

  Widget _buildHardwareSection(String title, List<HardwareComponent> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    final Map<String, List<HardwareComponent>> groupedItems = _groupHardwareComponentsBySku(items);

    return ExpansionTile(
      childrenPadding: EdgeInsets.zero,
      minTileHeight: 0,

      collapsedBackgroundColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      collapsedIconColor: primaryText,
      iconColor: accentColor,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Icon(icon, size: 16, color: secondaryText),
            // const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: fsRegular, color: primaryText, overflow: TextOverflow.ellipsis),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                items.length.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: fsSmall, color: primaryText, overflow: TextOverflow.ellipsis),
              ),
            ),

            Text(
              '\$${items.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: fsRegular,
                color: primaryText,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
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
            children: groupedItems.entries.map((MapEntry<String, List<HardwareComponent>> entry) => _buildHardwareItemRow(entry.key, entry.value)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _getItemName(item),
                  style: const TextStyle(
                    fontSize: fsSmall,
                    color: primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${_getItemPrice(item).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: fsSmall,
              color: primaryText,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _getItemName(sampleItem),
                  style: const TextStyle(
                    fontSize: fsSmall,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'x$quantity',
              style: const TextStyle(
                fontSize: fsSmall,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: fsSmall,
              color: primaryText,
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
    if (item is FusionDevice) return item.name ?? 'Unknown Fusion Device';
    return 'Unknown Item';
  }

  String? _getItemSku(dynamic item) {
    if (item is Speaker) return item.speakerSKU;
    if (item is Source) return item.sku;
    if (item is HardwareComponent) return item.hardwareName;
    if (item is Amplifier) return item.name;
    if (item is FusionDevice) return item.name;
    return null;
  }

  double _getItemPrice(dynamic item) {
    if (item is Speaker) return item.price;
    if (item is Source) return item.price;
    if (item is HardwareComponent) return item.price;
    if (item is Amplifier) return item.price;
    if (item is FusionDevice) return item.price;
    return 0.0;
  }

  int _calculateTotalItems() {
    return speakers.length + sources.length + controllers.length + racks.length + amplifiers.length + fusionDevices.length + others.length;
  }

  double _calculateTotalCost() {
    return speakers.totalPrice +
        sources.totalPrice +
        controllers.totalPrice +
        racks.totalPrice +
        amplifiers.totalPrice +
        fusionDevices.totalPrice +
        others.totalPrice;
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
      if (item is FusionDevice) return sum + item.price;
      return sum;
    });
  }
}
