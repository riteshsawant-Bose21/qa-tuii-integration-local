import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum Services { fusion }

class ServiceUUIDs {
  static final Map<Services, Guid> _uuids = <Services, Guid>{
    Services.fusion: Guid("B053"),
  };

  static Guid getUUID(Services service) {
    return _uuids[service]!;
  }
}

enum Characteristics {
  fusionControl,
}

class CharacteristicUUIDs {
  // Map of Characteristics to their UUIDs
  static final Map<Characteristics, Guid> _uuids = <Characteristics, Guid>{
    Characteristics.fusionControl: Guid("AD10"),
  };

  // Method to get the UUID for a given characteristic
  static Guid getUUID(Characteristics characteristic) {
    return _uuids[characteristic]!;
  }
}
