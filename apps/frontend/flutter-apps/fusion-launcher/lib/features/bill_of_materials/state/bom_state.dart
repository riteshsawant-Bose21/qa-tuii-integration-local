import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart'; // used in bom_state_modifier.dart (part file)
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/project_entities/controller.dart';
import 'package:fusion_lib/models/project_entities/endpoints.dart';
import 'package:fusion_lib/models/project_entities/network_switch.dart';

part 'bom_state_modifier.dart';

// ─── BOM Item model ───────────────────────────────────────────────────────────

class BomItem {
  final String id;
  final String name;
  final String model;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final String type;

  /// Product catalog ID — used to resolve the cached product image.
  final int? productId;

  const BomItem({
    required this.id,
    required this.name,
    required this.model,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    required this.type,
    this.productId,
  });

  BomItem copyWith({int? quantity}) {
    return BomItem(
      id: id,
      name: name,
      model: model,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      type: type,
      productId: productId,
    );
  }
}

// ─── Category enum ────────────────────────────────────────────────────────────

enum BomCategory {
  all,
  loudSpeakers,
  controllers,
  amplifiers,
  processors,
  endpoints,
  hardwareRequirements,
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class BomState {
  final List<BomItem> allItems;
  final List<BomItem> filteredItems;
  final BomCategory selectedCategory;
  final String searchQuery;

  BomState({
    required this.allItems,
    required this.filteredItems,
    required this.selectedCategory,
    required this.searchQuery,
  });

  double get totalPrice => allItems.fold(0.0, (double s, BomItem i) => s + i.unitPrice * i.quantity);
}

class BomIdleState extends BomState {
  BomIdleState({
    required super.allItems,
    required super.filteredItems,
    required super.selectedCategory,
    required super.searchQuery,
  });
}
