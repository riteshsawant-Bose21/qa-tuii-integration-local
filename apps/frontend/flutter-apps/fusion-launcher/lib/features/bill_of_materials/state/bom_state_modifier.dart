part of 'bom_state.dart';

extension BomStateMethods on BomState {
  // ─── Data Loading ──────────────────────────────────────────────────────────

  static List<BomItem> _loadAllItems() {
    final ProjectViewModel vm = serviceLocator<ProjectViewModel>();
    final ProductQueryViewModel pq = serviceLocator<ProductQueryViewModel>();

    String? productImage(String? storedPath, int? productId) {
      if (productId != null) {
        final String? catalogPath = pq.getProductImage(productId);
        if (catalogPath != null && catalogPath.isNotEmpty) return catalogPath;
      }
      return (storedPath != null && storedPath.isNotEmpty) ? storedPath : null;
    }

    double productPrice(double storedPrice, int? productId) {
      if (productId != null) {
        final double catalogPrice = pq.getPrice(productId);
        if (catalogPrice > 0) return catalogPrice;
      }
      return storedPrice;
    }

    final Map<String, BomItem> aggregated = <String, BomItem>{};

    void add(BomItem item) {
      final String key = '${item.type}__${item.model}';
      final BomItem? existing = aggregated[key];
      aggregated[key] = existing == null ? item : existing.copyWith(quantity: existing.quantity + 1);
    }

    // Loud Speakers
    for (final Speaker speaker in vm.speakers) {
      add(
        BomItem(
          id: speaker.id,
          name: speaker.name,
          model: speaker.speakerSKU,
          unitPrice: productPrice(speaker.price, speaker.productId),
          quantity: 1,
          imageUrl: productImage(speaker.image, speaker.productId),
          type: 'Loud Speaker',
          productId: speaker.productId,
        ),
      );
    }

    // Amplifiers
    for (final Amplifier amp in vm.amplifiers) {
      add(
        BomItem(
          id: amp.id,
          name: amp.name,
          model: amp.hardwareName,
          unitPrice: amp.price,
          quantity: 1,
          imageUrl: productImage(amp.image, null),
          type: 'Amplifier',
        ),
      );
    }

    // Processors / DSPs
    for (final FusionDsp dsp in vm.fusionDsps) {
      add(
        BomItem(
          id: dsp.id,
          name: dsp.name,
          model: dsp.hardwareName,
          unitPrice: dsp.price,
          quantity: 1,
          imageUrl: productImage(dsp.image, null),
          type: 'Processor',
        ),
      );
    }

    // Controllers
    for (final FusionController ctrl in vm.fusionControllers) {
      add(
        BomItem(
          id: ctrl.id,
          name: ctrl.name,
          model: ctrl.hardwareName,
          unitPrice: ctrl.price,
          quantity: 1,
          imageUrl: productImage(ctrl.image, null),
          type: 'Controller',
        ),
      );
    }

    // Endpoints
    for (final FusionEndpoints ep in vm.fusionEndpoints) {
      add(
        BomItem(id: ep.id, name: ep.name, model: ep.hardwareName, unitPrice: ep.price, quantity: 1, imageUrl: productImage(ep.image, null), type: 'Endpoint'),
      );
    }

    // Network Switches
    for (final NetworkSwitch sw in vm.networkSwitches) {
      add(
        BomItem(
          id: sw.id,
          name: sw.name,
          model: sw.hardwareName,
          unitPrice: sw.price,
          quantity: 1,
          imageUrl: productImage(sw.image, null),
          type: 'Network Switch',
        ),
      );
    }

    // Generic – Other (racks excluded)
    for (final GenericHardwareComponent other in vm.genericHardwareComponents.where(
      (GenericHardwareComponent c) => c.type == GenericHardwareComponentType.other,
    )) {
      add(
        BomItem(
          id: other.id,
          name: other.name,
          model: other.hardwareName,
          unitPrice: other.price,
          quantity: 1,
          imageUrl: productImage(other.image, null),
          type: 'Other',
        ),
      );
    }

    return aggregated.values.toList();
  }

  static List<BomItem> _applyFilter(List<BomItem> items, BomCategory category, String query) {
    List<BomItem> result = items;

    switch (category) {
      case BomCategory.loudSpeakers:
        result = result.where((BomItem i) => i.type == 'Loud Speaker').toList();
        break;
      case BomCategory.controllers:
        result = result.where((BomItem i) => i.type == 'Controller').toList();
        break;
      case BomCategory.amplifiers:
        result = result.where((BomItem i) => i.type == 'Amplifier').toList();
        break;
      case BomCategory.processors:
        result = result.where((BomItem i) => i.type == 'Processor').toList();
        break;
      case BomCategory.endpoints:
        result = result.where((BomItem i) => i.type == 'Endpoint').toList();
        break;
      case BomCategory.all:
      case BomCategory.hardwareRequirements:
        break;
    }

    if (query.isNotEmpty) {
      final String q = query.toLowerCase();
      result = result.where((BomItem i) => i.name.toLowerCase().contains(q) || i.model.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  // ─── State Transitions ─────────────────────────────────────────────────────

  BomState refresh() {
    final List<BomItem> all = _loadAllItems();
    final List<BomItem> filtered = _applyFilter(all, selectedCategory, searchQuery);
    return BomIdleState(
      allItems: all,
      filteredItems: filtered,
      selectedCategory: selectedCategory,
      searchQuery: searchQuery,
    );
  }

  BomState changeCategory(BomCategory category) {
    final List<BomItem> filtered = _applyFilter(allItems, category, searchQuery);
    return BomIdleState(
      allItems: allItems,
      filteredItems: filtered,
      selectedCategory: category,
      searchQuery: searchQuery,
    );
  }

  BomState search(String query) {
    final List<BomItem> filtered = _applyFilter(allItems, selectedCategory, query);
    return BomIdleState(
      allItems: allItems,
      filteredItems: filtered,
      selectedCategory: selectedCategory,
      searchQuery: query,
    );
  }
}
