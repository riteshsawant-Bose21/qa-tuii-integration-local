/// Product types enum
enum ProductType {
  speaker,
  endpoints,
  amplifier,
  sources,
  dsps,
  controllers,
  racks,
}

/// Sort options enum
enum SortOption {
  priceHighToLow,
  priceLowToHigh,
  nameAToZ,
  nameZToA,
}

/// Coverage levels enum
enum CoverageLevel {
  low,
  mid,
  high,
}

/// Impedance levels enum
enum ImpedanceLevel {
  low,
  high,
}

/// Zone and SubZone menu actions enum
enum ZoneMenuAction {
  edit,
  subzone,
  delete,
}

/// Device search scope enum (used for narrowing grouped section search results)
enum DeviceSearchScope {
  sources,
  endpoints,
  fusionDevices,
  amplifiers,
  racks,
  switches,
}
