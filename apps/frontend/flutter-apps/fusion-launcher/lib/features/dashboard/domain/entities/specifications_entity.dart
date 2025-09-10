enum VenueType { indoor, outdoor, hybrid }

enum ProductType {
  processor,
  amplifier,
  speaker,
  controller,
  accessory,
}

class VenueSpec {
  String name;
  VenueType type;

  VenueSpec({this.name = '', this.type = VenueType.indoor});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'type': type.toString().split('.').last,
  };

  VenueSpec copyWith({
    String? name,
    VenueType? type,
  }) {
    return VenueSpec(
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

/// Per‐room details
class RoomSpec {
  String name;
  double ceilingHeight;
  double roomLength;
  double roomBreadth;
  int inputDevices;
  int speakers;

  RoomSpec({
    this.name = '',
    this.ceilingHeight = 0,
    this.roomLength = 0,
    this.roomBreadth = 0,
    this.inputDevices = 0,
    this.speakers = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'ceilingHeight': ceilingHeight,
    'roomLength': roomLength,
    'roomBreadth': roomBreadth,
    'inputDevices': inputDevices,
    'speakers': speakers,
  };

  RoomSpec copyWith({
    String? name,
    double? ceilingHeight,
    double? roomLength,
    double? roomBreadth,
    int? inputDevices,
    int? speakers,
  }) {
    return RoomSpec(
      name: name ?? this.name,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      roomLength: roomLength ?? this.roomLength,
      roomBreadth: roomBreadth ?? this.roomBreadth,
      inputDevices: inputDevices ?? this.inputDevices,
      speakers: speakers ?? this.speakers,
    );
  }
}

class FloorSpec {
  String name;
  double ceilingHeight;
  List<RoomSpec> rooms;

  FloorSpec({
    this.name = '',
    this.ceilingHeight = 2.5,
    List<RoomSpec>? rooms,
  }) : rooms = rooms ?? <RoomSpec>[];

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'ceilingHeight': ceilingHeight,
    'rooms': rooms.map((RoomSpec r) => r.toJson()).toList(),
  };

  FloorSpec copyWith({
    String? name,
    double? ceilingHeight,
    List<RoomSpec>? rooms,
  }) {
    return FloorSpec(
      name: name ?? this.name,
      ceilingHeight: ceilingHeight ?? this.ceilingHeight,
      rooms: rooms ?? this.rooms,
    );
  }
}

class ProductSpec {
  ProductType type;
  String name;
  int quantity;
  double price; // newly added

  ProductSpec({
    this.type = ProductType.processor,
    this.name = '',
    this.quantity = 1,
    this.price = 0.0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.toString().split('.').last,
    'name': name,
    'quantity': quantity,
    'price': price,
  };

  ProductSpec copyWith({
    ProductType? type,
    String? name,
    int? quantity,
    double? price,
  }) {
    return ProductSpec(
      type: type ?? this.type,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}

class SpecificationEntity {
  VenueSpec venue;
  List<FloorSpec> floors;
  List<ProductSpec> products;

  bool isEmpty() {
    return venue.name.isEmpty && floors.isEmpty && products.isEmpty;
  }

  SpecificationEntity({
    VenueSpec? venue,
    List<FloorSpec>? floors,
    List<ProductSpec>? products,
  }) : venue = venue ?? VenueSpec(),
       floors = floors ?? <FloorSpec>[],
       products = products ?? <ProductSpec>[];

  SpecificationEntity copyWith({
    VenueSpec? venue,
    List<FloorSpec>? floors,
    List<ProductSpec>? products,
  }) {
    return SpecificationEntity(
      venue: venue ?? this.venue,
      floors: floors ?? this.floors,
      products: products ?? this.products,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'venue': venue.toJson(),
    'floors': floors.map((FloorSpec z) => z.toJson()).toList(),
    'products': products.map((ProductSpec p) => p.toJson()).toList(),
  };

  clone() {
    return SpecificationEntity(
      venue: venue.copyWith(),
      floors: floors.map((FloorSpec f) => f.copyWith()).toList(),
      products: products.map((ProductSpec p) => p.copyWith()).toList(),
    );
  }
}
