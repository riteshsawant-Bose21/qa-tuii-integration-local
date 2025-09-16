class DeviceItemModel {
  final String sku;
  final String name;
  final String image;

  const DeviceItemModel({
    required this.sku,
    required this.name,
    required this.image,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DeviceItemModel && runtimeType == other.runtimeType && sku == other.sku && name == other.name && image == other.image;

  @override
  int get hashCode => sku.hashCode ^ name.hashCode ^ image.hashCode;

  @override
  String toString() => 'DeviceItemModel(sku: $sku, name: $name, image: $image)';
}
