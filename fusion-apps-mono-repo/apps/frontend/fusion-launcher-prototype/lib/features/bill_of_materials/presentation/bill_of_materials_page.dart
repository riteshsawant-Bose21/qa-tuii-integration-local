import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/models/amplifer.dart';
import 'package:fusion_design_tool_prototype/core/models/fusion_device.dart';
import 'package:fusion_design_tool_prototype/core/models/hardware_component_entity.dart';
import 'package:fusion_design_tool_prototype/core/models/source_entity.dart';
import 'package:fusion_design_tool_prototype/core/models/speaker_entity.dart';

import '../../../core/models/generic_hardware_component_entity.dart';
import '../../../core/models/project_entity.dart';
import '../../../core/service_locator.dart';
import '../../../core/services/project_manager.dart';

class BillOfMaterialsPage extends StatefulWidget {
  const BillOfMaterialsPage({
    super.key,
  });

  @override
  State<BillOfMaterialsPage> createState() => _BillOfMaterialsPageState();
}

class _BillOfMaterialsPageState extends State<BillOfMaterialsPage> {
  final ProjectManager projectManager = serviceLocator<ProjectManager>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color backgroundColor = Color(0xFFFAFAFA);

  List<Speaker> speakers = <Speaker>[];
  List<Source> sources = <Source>[];
  List<HardwareComponent> controllers = <HardwareComponent>[];
  List<HardwareComponent> racks = <HardwareComponent>[];
  List<Amplifier> amplifiers = <Amplifier>[];
  List<FusionDevice> fusionDevices = <FusionDevice>[];
  List<HardwareComponent> others = <HardwareComponent>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BOMItem> _getAllItems() {
    // 1) Build a flat list of every item (quantity = 1 each)
    final List<BOMItem> rawItems = <BOMItem>[];

    // Add speakers
    for (Speaker speaker in speakers) {
      rawItems.add(
        BOMItem(
          id: speaker.id ?? '',
          name: speaker.name ?? 'Unknown Speaker',
          model: speaker.speakerSKU ?? 'Unknown Model',
          unitPrice: speaker.price,
          quantity: 1,
          imageUrl: speaker.assetImagePath,
          type: 'Speaker',
        ),
      );
    }

    // Add sources
    for (Source source in sources) {
      rawItems.add(
        BOMItem(
          id: source.id ?? '',
          name: source.name ?? 'Unknown Source',
          model: source.sku ?? 'Unknown Model',
          unitPrice: source.price,
          quantity: 1,
          imageUrl: source.assetImagePath,
          type: 'Source',
        ),
      );
    }

    // Add controllers
    for (HardwareComponent controller in controllers) {
      rawItems.add(
        BOMItem(
          id: controller.id ?? '',
          name: controller.name ?? 'Unknown Controller',
          model: controller.hardwareName ?? 'Unknown Model',
          unitPrice: controller.price,
          quantity: 1,
          imageUrl: controller.assetImagePath,
          type: 'Controller',
        ),
      );
    }

    // Add racks
    for (HardwareComponent rack in racks) {
      rawItems.add(
        BOMItem(
          id: rack.id ?? '',
          name: rack.name ?? 'Unknown Rack',
          model: rack.hardwareName ?? 'Unknown Model',
          unitPrice: rack.price,
          quantity: 1,
          imageUrl: rack.assetImagePath,
          type: 'Rack',
        ),
      );
    }

    // Add amplifiers
    for (Amplifier amp in amplifiers) {
      rawItems.add(
        BOMItem(
          id: amp.id ?? '',
          name: amp.name ?? 'Unknown Amplifier',
          model: amp.name ?? 'Unknown Model',
          unitPrice: amp.price,
          quantity: 1,
          imageUrl: "assets/images/amplifier_img.webp",
          type: 'Amplifier',
        ),
      );
    }

    // Add fusion devices
    for (FusionDevice device in fusionDevices) {
      rawItems.add(
        BOMItem(
          id: device.id ?? '',
          name: device.name ?? 'Unknown Fusion Device',
          model: device.name ?? 'Unknown Model',
          unitPrice: device.price,
          quantity: 1,
          imageUrl: "assets/images/processor_img.webp",
          type: 'Fusion Device',
        ),
      );
    }

    // Add others
    for (HardwareComponent other in others) {
      rawItems.add(
        BOMItem(
          id: other.id ?? '',
          name: other.name ?? 'Unknown Component',
          model: other.hardwareName ?? 'Unknown Model',
          unitPrice: other.price,
          quantity: 1,
          imageUrl: other.assetImagePath,
          type: 'Other',
        ),
      );
    }

    // 2) Aggregate by model, summing quantities
    final Map<String, BOMItem> aggregated = <String, BOMItem>{};
    for (final BOMItem item in rawItems) {
      final String key = item.model;
      if (aggregated.containsKey(key)) {
        final BOMItem existing = aggregated[key]!;
        aggregated[key] = BOMItem(
          id: existing.id, // keep the first ID
          name: existing.name,
          model: existing.model,
          unitPrice: existing.unitPrice,
          quantity: existing.quantity + item.quantity,
          imageUrl: existing.imageUrl,
          type: existing.type,
        );
      } else {
        aggregated[key] = item;
      }
    }

    // 3) Return the deduped list
    return aggregated.values.toList();
  }

  List<BOMItem> _getFilteredItems() {
    final List<BOMItem> allItems = _getAllItems();
    if (_searchQuery.isEmpty) return allItems;

    return allItems.where((BOMItem item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) || item.model.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  double _calculateTotalPrice() {
    return _getAllItems().fold(0.0, (double sum, BOMItem item) => sum + (item.unitPrice * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: ValueListenableBuilder<ProjectEntity>(
        valueListenable: projectManager,
        builder: (BuildContext context, ProjectEntity data, _) {
          speakers = data.hardwareComponents.whereType<Speaker>().toList();
          sources = data.hardwareComponents.whereType<Source>().toList();
          controllers =
              data.hardwareComponents
                  .whereType<GenericHardwareComponent>()
                  .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.controller)
                  .toList();
          racks =
              data.hardwareComponents
                  .whereType<GenericHardwareComponent>()
                  .where((GenericHardwareComponent component) => component.type == GenericHardwareComponentType.rack)
                  .toList();
          amplifiers = data.amplifiers;
          fusionDevices = data.suggestedFusionDevices;
          others =
              data.hardwareComponents
                  .where(
                    (HardwareComponent component) => component is GenericHardwareComponent && component.type == GenericHardwareComponentType.other,
                  )
                  .toList();

          final List<BOMItem> filteredItems = _getFilteredItems();
          final double totalPrice = _getAllItems().fold(0.0, (double sum, BOMItem item) => sum + item.unitPrice * item.quantity);
          final double vatAmount = totalPrice * 0.0161; // 1.61%
          const double orgDiscount = 400.0;
          final double grandTotal = totalPrice + vatAmount - orgDiscount;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Product Table
                Expanded(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 60,
                        child: Row(
                          children: <Widget>[
                            const Text(
                              'Product List',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                              ),
                            ),
                            const Spacer(),
                            // Search Bar
                            Container(
                              width: 300,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(color: secondaryText),
                                  prefixIcon: Icon(Icons.search, color: secondaryText),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: <Widget>[
                              // Table Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  children: <Widget>[
                                    SizedBox(width: 60, child: Text('', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                    Expanded(flex: 2, child: Text('Item', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                    Expanded(flex: 2, child: Text('Model/Variant', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                    SizedBox(width: 100, child: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                    SizedBox(width: 80, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                    SizedBox(width: 100, child: Text('Price', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                    SizedBox(width: 60, child: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: secondaryText))),
                                  ],
                                ),
                              ),
                              // Table Body
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredItems.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final BOMItem item = filteredItems[index];
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: borderColor.withOpacity(0.5)),
                                        ),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          // Image
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child:
                                                item.imageUrl != null
                                                    ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: Image.asset(item.imageUrl!),
                                                    )
                                                    : const Icon(Icons.device_unknown, color: secondaryText),
                                          ),
                                          const SizedBox(width: 20),
                                          // Item Name
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: primaryText,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          // Model
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              item.model,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: primaryText,
                                              ),
                                            ),
                                          ),
                                          // Unit Price
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              '\$ ${item.unitPrice.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: primaryText,
                                              ),
                                            ),
                                          ),
                                          // Quantity
                                          SizedBox(
                                            width: 80,
                                            child: Row(
                                              children: <Widget>[
                                                Text(
                                                  '${item.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: primaryText,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.keyboard_arrow_up,
                                                  size: 16,
                                                  color: secondaryText,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Price
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              '\$ ${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: primaryText,
                                              ),
                                            ),
                                          ),
                                          // Action
                                          SizedBox(
                                            width: 60,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 14.0,
                                                color: secondaryText,
                                              ),
                                              onPressed: () {
                                                // Handle delete action
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Pricing Summary
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Pricing',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Price Summary
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Total Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                  ),
                                ),
                                Text(
                                  '\$${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'VAT/ Tax',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                  ),
                                ),
                                Text(
                                  '\$${vatAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Org Discount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                  ),
                                ),
                                Text(
                                  '\$${orgDiscount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: borderColor),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'Grand Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '\$${grandTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Proceed Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle proceed action
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'PROCEED',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Handle print action
                                    },
                                    icon: const Icon(Icons.print_outlined, size: 14),
                                    label: const Text(
                                      'Print',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: secondaryText,
                                      side: const BorderSide(color: borderColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Handle export BOM action
                                    },
                                    icon: const Icon(Icons.file_download_outlined, size: 14),
                                    label: const Text(
                                      'Export BOM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: secondaryText,
                                      side: const BorderSide(color: borderColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BOMItem {
  final String id;
  final String name;
  final String model;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final String type;

  BOMItem({
    required this.id,
    required this.name,
    required this.model,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    required this.type,
  });
}
