class ProductsConfigurationEntity {
  final Map<String, Set<String>> productsConfig;

  ProductsConfigurationEntity({required this.productsConfig});

  ProductsConfigurationEntity copyWith({
    Map<String, Set<String>>? productsConfig,
  }) {
    return ProductsConfigurationEntity(
      productsConfig: productsConfig ?? this.productsConfig,
    );
  }

  reset() {
    productsConfig.clear();
  }

  clone() {
    return ProductsConfigurationEntity(
      productsConfig: Map<String, Set<String>>.from(productsConfig),
    );
  }

  @override
  String toString() {
    return 'ProductsConfigurationEntity(productsConfig: $productsConfig)';
  }
}
