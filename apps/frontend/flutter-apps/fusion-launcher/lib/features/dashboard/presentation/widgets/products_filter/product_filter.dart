import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Enum for sorting options
enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  nameAToZ,
  nameZToA,
}

/// Enum for coverage levels (derived from max SPL)
enum CoverageLevel {
  low,
  mid,
  high,
}

/// Enum for impedance levels
enum ImpedanceLevel {
  low,
  high,
}

/// Clean and modern product filter with separate category filters
class ProductFilterPage extends StatefulWidget {
  const ProductFilterPage({super.key});

  @override
  State<ProductFilterPage> createState() => _ProductFilterPageState();
}

class _ProductFilterPageState extends State<ProductFilterPage> {
  final TextEditingController _searchController = TextEditingController();
  final FusionDevices _fusionDevices = FusionDevices();
  
  // Product type filter
  String selectedProductType = 'All'; // All, Speakers, Amplifiers, DSP Devices
  
  // Speaker-specific filters
  Set<String> selectedMountTypes = <String>{};
  Set<String> selectedVenueTypes = <String>{};
  Set<String> selectedColors = <String>{};
  Set<CoverageLevel> selectedCoverage = <CoverageLevel>{};
  
  // Amplifier-specific filters
  Set<String> selectedChannelCounts = <String>{}; // 2, 4, 8, etc.
  Set<String> selectedPowerRanges = <String>{}; // Low, Mid, High power
  
  // DSP-specific filters
  Set<String> selectedInputCounts = <String>{}; // Number of inputs
  Set<String> selectedOutputCounts = <String>{}; // Number of outputs
  Set<String> selectedNetworkTypes = <String>{}; // Ethernet, Dante, etc.
  
  // Common filters
  Set<ImpedanceLevel> selectedImpedance = <ImpedanceLevel>{};
  SortOption selectedSort = SortOption.nameAToZ;
  
  // SPL Range state
  RangeValues splRange = const RangeValues(70, 120);
  
  // Data
  List<ProductItem> allProducts = <ProductItem>[];
  List<ProductItem> filteredProducts = <ProductItem>[];
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadProducts() {
    allProducts = <ProductItem>[];
    
    try {
      // Load speakers
      final String speakersJson = _fusionDevices.getSpeakers();
      if (speakersJson.isNotEmpty && speakersJson != '[]') {
        final List<ProductItem> speakers = (jsonDecode(speakersJson) as List<dynamic>)
            .map((dynamic json) => SpeakerModel.fromJson(json as Map<String, dynamic>))
            .map((SpeakerModel speaker) => ProductItem.fromSpeaker(speaker))
            .toList();
        allProducts.addAll(speakers);
      }
      
      // Load amplifiers
      final String ampsJson = _fusionDevices.getAmplifiers();
      if (ampsJson.isNotEmpty && ampsJson != '[]') {
        final List<ProductItem> amplifiers = (jsonDecode(ampsJson) as List<dynamic>)
            .map((dynamic json) => AmpModel.fromJson(json as Map<String, dynamic>))
            .map((AmpModel amp) => ProductItem.fromAmplifier(amp))
            .toList();
        allProducts.addAll(amplifiers);
      }
      
      // Load devices
      final String devicesJson = _fusionDevices.getDevices();
      if (devicesJson.isNotEmpty && devicesJson != '[]') {
        final List<ProductItem> devices = (jsonDecode(devicesJson) as List<dynamic>)
            .map((dynamic json) => DeviceSpec.fromJson(json as Map<String, dynamic>))
            .map((DeviceSpec device) => ProductItem.fromDevice(device))
            .toList();
        allProducts.addAll(devices);
      }
    } catch (e) {
      // If there's an error loading data, we'll still have empty lists
      // This prevents the app from crashing and shows empty results
      // In production, this should be logged properly
    }
    
    _applyFilters();
  }
  
  void _onSearchChanged() {
    _applyFilters();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Light neutral background
      body: SafeArea(
        top: false, // Remove top safe area to eliminate gap
        child: Column(
          children: <Widget>[
            // Header with title
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Product Browser',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse and filter Bose Professional products',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF0EA5E9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${allProducts.length} Products Available',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search and sort bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                // Search bar
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search products…',
                        hintStyle: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search_outlined,
                          color: Color(0xFF757575),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Sort dropdown
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: DropdownButton<SortOption>(
                    value: selectedSort,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: Color(0xFF757575),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF212121),
                      fontSize: 14,
                    ),
                    onChanged: (SortOption? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedSort = newValue;
                        });
                        _applyFilters();
                      }
                    },
                    items: SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption value) {
                      return DropdownMenuItem<SortOption>(
                        value: value,
                        child: Text(_getSortLabelForOption(value)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content with sidebar and products
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Left sidebar
                Container(
                  width: 280,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildProductTypeFilter(),
                        const SizedBox(height: 24),
                        _buildCategorySpecificFilters(),
                        const SizedBox(height: 24),
                        _buildClearFiltersButton(),
                      ],
                    ),
                  ),
                ),
                
                // Products grid
                Expanded(
                  child: _buildProductsGrid(),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
  
  Widget _buildProductTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Product Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        // Product count display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Total: ${allProducts.length} | Showing: ${filteredProducts.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...<String>['All', 'Speakers', 'Amplifiers', 'DSP Devices'].map((String type) {
          final bool isSelected = selectedProductType == type;
          
          // Calculate count for this type
          int typeCount = 0;
          if (type == 'All') {
            typeCount = allProducts.length;
          } else if (type == 'Speakers') {
            typeCount = allProducts.where((ProductItem p) => p.type == 'Speaker').length;
          } else if (type == 'Amplifiers') {
            typeCount = allProducts.where((ProductItem p) => p.type == 'Amplifier').length;
          } else if (type == 'DSP Devices') {
            typeCount = allProducts.where((ProductItem p) => p.type == 'DSP Device').length;
          }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedProductType = type;
                });
                _applyFilters();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _getProductTypeIcon(type),
                      size: 18,
                      color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF757575),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF424242),
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$typeCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.white : const Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_outlined,
                        size: 16,
                        color: Color(0xFF0EA5E9),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  IconData _getProductTypeIcon(String type) {
    switch (type) {
      case 'All':
        return Icons.dashboard_outlined;
      case 'Speakers':
        return Icons.speaker_outlined;
      case 'Amplifiers':
        return Icons.settings_input_component_outlined;
      case 'DSP Devices':
        return Icons.tune_outlined;
      default:
        return Icons.device_unknown_outlined;
    }
  }
  
  Widget _buildCategorySpecificFilters() {
    switch (selectedProductType) {
      case 'Speakers':
        return _buildSpeakerFilters();
      case 'Amplifiers':
        return _buildAmplifierFilters();
      case 'DSP Devices':
        return _buildDspFilters();
      default:
        return _buildAllProductsFilters();
    }
  }
  
  Widget _buildSpeakerFilters() {
    return Column(
      children: <Widget>[
        _buildFilterSection(
          'Mount Type',
          Icons.vertical_align_top_outlined,
          <String>['Ceiling', 'Surface', 'Pendant'],
          selectedMountTypes,
          (String value) {
            setState(() {
              if (selectedMountTypes.contains(value)) {
                selectedMountTypes.remove(value);
              } else {
                selectedMountTypes.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildFilterSection(
          'Venue Type',
          Icons.location_on_outlined,
          <String>['Indoor', 'Outdoor'],
          selectedVenueTypes,
          (String value) {
            setState(() {
              if (selectedVenueTypes.contains(value)) {
                selectedVenueTypes.remove(value);
              } else {
                selectedVenueTypes.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildColorFilter(),
        const SizedBox(height: 20),
        _buildCoverageFilter(),
      ],
    );
  }
  
  Widget _buildAmplifierFilters() {
    // Get available channel counts from actual amplifier data
    final Set<String> availableChannels = allProducts
        .where((ProductItem p) => p.type == 'Amplifier')
        .map((ProductItem p) => p.additionalInfo['channels']?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toSet();
    
    return Column(
      children: <Widget>[
        _buildFilterSection(
          'Channel Count',
          Icons.linear_scale_outlined,
          availableChannels.toList()..sort(),
          selectedChannelCounts,
          (String value) {
            setState(() {
              if (selectedChannelCounts.contains(value)) {
                selectedChannelCounts.remove(value);
              } else {
                selectedChannelCounts.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildFilterSection(
          'Power Range',
          Icons.power_outlined,
          <String>['Low Power (≤600W)', 'Mid Power (600-1200W)', 'High Power (>1200W)'],
          selectedPowerRanges,
          (String value) {
            setState(() {
              if (selectedPowerRanges.contains(value)) {
                selectedPowerRanges.remove(value);
              } else {
                selectedPowerRanges.add(value);
              }
            });
            _applyFilters();
          },
        ),
      ],
    );
  }
  
  Widget _buildDspFilters() {
    // Get available input/output counts from actual DSP device data
    final Set<String> availableInputs = allProducts
        .where((ProductItem p) => p.type == 'DSP Device')
        .map((ProductItem p) => p.additionalInfo['analogInputs']?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toSet();
        
    final Set<String> availableOutputs = allProducts
        .where((ProductItem p) => p.type == 'DSP Device')
        .map((ProductItem p) => p.additionalInfo['analogOutputs']?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toSet();
    
    return Column(
      children: <Widget>[
        _buildFilterSection(
          'Input Count',
          Icons.input_outlined,
          availableInputs.toList()..sort(),
          selectedInputCounts,
          (String value) {
            setState(() {
              if (selectedInputCounts.contains(value)) {
                selectedInputCounts.remove(value);
              } else {
                selectedInputCounts.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildFilterSection(
          'Output Count',
          Icons.output_outlined,
          availableOutputs.toList()..sort(),
          selectedOutputCounts,
          (String value) {
            setState(() {
              if (selectedOutputCounts.contains(value)) {
                selectedOutputCounts.remove(value);
              } else {
                selectedOutputCounts.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildFilterSection(
          'Network Type',
          Icons.network_check_outlined,
          <String>['Network I/O', 'Analog Only'],
          selectedNetworkTypes,
          (String value) {
            setState(() {
              if (selectedNetworkTypes.contains(value)) {
                selectedNetworkTypes.remove(value);
              } else {
                selectedNetworkTypes.add(value);
              }
            });
            _applyFilters();
          },
        ),
      ],
    );
  }
  
  Widget _buildAllProductsFilters() {
    return Column(
      children: <Widget>[
        _buildFilterSection(
          'Mount Type',
          Icons.vertical_align_top_outlined,
          <String>['Ceiling', 'Surface', 'Pendant'],
          selectedMountTypes,
          (String value) {
            setState(() {
              if (selectedMountTypes.contains(value)) {
                selectedMountTypes.remove(value);
              } else {
                selectedMountTypes.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildFilterSection(
          'Venue Type',
          Icons.location_on_outlined,
          <String>['Indoor', 'Outdoor'],
          selectedVenueTypes,
          (String value) {
            setState(() {
              if (selectedVenueTypes.contains(value)) {
                selectedVenueTypes.remove(value);
              } else {
                selectedVenueTypes.add(value);
              }
            });
            _applyFilters();
          },
        ),
        const SizedBox(height: 20),
        _buildColorFilter(),
        const SizedBox(height: 20),
        _buildCoverageFilter(),
      ],
    );
  }
  
  Widget _buildFilterSection(
    String title,
    IconData icon,
    List<String> options,
    Set<String> selectedItems,
    Function(String) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF757575),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...options.map((String option) {
          final bool isSelected = selectedItems.contains(option);
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () => onTap(option),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFBDBDBD),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? const Color(0xFF212121) : const Color(0xFF616161),
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildColorFilter() {
    // Get available colors from actual speaker data
    final Set<String> availableColors = allProducts
        .where((ProductItem p) => p.type == 'Speaker' && p.color != null)
        .map((ProductItem p) => p.color!)
        .toSet();
    
    if (availableColors.isEmpty) {
      return const SizedBox.shrink(); // Don't show filter if no colors available
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.palette_outlined,
              size: 16,
              color: Color(0xFF757575),
            ),
            SizedBox(width: 8),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: availableColors.map((String color) {
            final bool isSelected = selectedColors.contains(color);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (selectedColors.contains(color)) {
                        selectedColors.remove(color);
                      } else {
                        selectedColors.add(color);
                      }
                    });
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color.toLowerCase() == 'white' ? Colors.white : Colors.black,
                            border: Border.all(
                              color: const Color(0xFFBDBDBD),
                              width: 1,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          color,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF616161),
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCoverageFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.radio_button_checked_outlined,
              size: 16,
              color: Color(0xFF757575),
            ),
            SizedBox(width: 8),
            Text(
              'Coverage',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: CoverageLevel.values.map((CoverageLevel level) {
            final bool isSelected = selectedCoverage.contains(level);
            final String label = level.toString().split('.').last;
            final String capitalizedLabel = label[0].toUpperCase() + label.substring(1);
            
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (selectedCoverage.contains(level)) {
                        selectedCoverage.remove(level);
                      } else {
                        selectedCoverage.add(level);
                      }
                    });
                    _applyFilters();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      capitalizedLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF616161),
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildClearFiltersButton() {
    final int activeFilters = _getActiveFilterCount();
    if (activeFilters == 0) return const SizedBox.shrink();
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _clearAllFilters,
        icon: const Icon(
          Icons.clear_outlined,
          size: 16,
          color: Color(0xFF757575),
        ),
        label: Text(
          'Clear All ($activeFilters)',
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductsGrid() {
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Color(0xFFBDBDBD),
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75, // Adjusted for better image to content ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (BuildContext context, int index) {
        final ProductItem product = filteredProducts[index];
        return CleanProductCard(
          product: product,
          onTap: () => _showProductDetails(context, product),
        );
      },
    );
  }
  
  void _clearAllFilters() {
    setState(() {
      selectedMountTypes.clear();
      selectedVenueTypes.clear();
      selectedColors.clear();
      selectedCoverage.clear();
      selectedImpedance.clear();
      selectedChannelCounts.clear();
      selectedPowerRanges.clear();
      selectedInputCounts.clear();
      selectedOutputCounts.clear();
      selectedNetworkTypes.clear();
      splRange = const RangeValues(70, 120);
      selectedSort = SortOption.nameAToZ;
      selectedProductType = 'All';
    });
    _applyFilters();
  }
  
  // Update _applyFilters to include product type filtering
  void _applyFilters() {
    setState(() {
      filteredProducts = allProducts.where((ProductItem product) {
        // Product type filter
        if (selectedProductType != 'All') {
          if (selectedProductType == 'Speakers' && product.type != 'Speaker') return false;
          if (selectedProductType == 'Amplifiers' && product.type != 'Amplifier') return false;
          if (selectedProductType == 'DSP Devices' && product.type != 'DSP Device') return false;
        }
        
        // Search filter
        final String query = _searchController.text.toLowerCase();
        if (query.isNotEmpty && 
            !product.name.toLowerCase().contains(query) &&
            !product.type.toLowerCase().contains(query)) {
          return false;
        }
        
        // Mount type filter (speakers only)
        if (selectedMountTypes.isNotEmpty && 
            product.mountType != null &&
            !selectedMountTypes.contains(product.mountType)) {
          return false;
        }
        
        // Venue type filter
        if (selectedVenueTypes.isNotEmpty && 
            product.venueType != null &&
            !selectedVenueTypes.contains(product.venueType)) {
          return false;
        }
        
        // Color filter
        if (selectedColors.isNotEmpty && 
            product.color != null &&
            !selectedColors.contains(product.color)) {
          return false;
        }
        
        // Coverage filter
        if (selectedCoverage.isNotEmpty && 
            product.coverage != null &&
            !selectedCoverage.contains(product.coverage)) {
          return false;
        }
        
        // SPL range filter (only applies to speakers with maxSpl data)
        if (product.additionalInfo.containsKey('maxSpl')) {
          final double maxSpl = product.additionalInfo['maxSpl'] as double;
          if (maxSpl < splRange.start || maxSpl > splRange.end) {
            return false;
          }
        }
        
        // Amplifier-specific filters
        if (product.type == 'Amplifier') {
          // Channel count filter
          if (selectedChannelCounts.isNotEmpty && 
              product.additionalInfo.containsKey('channels')) {
            final int channels = product.additionalInfo['channels'] as int;
            final String channelStr = channels.toString();
            if (!selectedChannelCounts.contains(channelStr)) {
              return false;
            }
          }
          
          // Power range filter
          if (selectedPowerRanges.isNotEmpty && 
              product.additionalInfo.containsKey('peakPerChannel')) {
            final double power = product.additionalInfo['peakPerChannel'] as double;
            String powerRange = '';
            if (power <= 600) {
              powerRange = 'Low Power (≤600W)';
            } else if (power <= 1200) {
              powerRange = 'Mid Power (600-1200W)';
            } else {
              powerRange = 'High Power (>1200W)';
            }
            if (!selectedPowerRanges.contains(powerRange)) {
              return false;
            }
          }
        }
        
        // DSP Device-specific filters
        if (product.type == 'DSP Device') {
          // Input count filter
          if (selectedInputCounts.isNotEmpty && 
              product.additionalInfo.containsKey('analogInputs')) {
            final int inputs = product.additionalInfo['analogInputs'] as int;
            final String inputStr = inputs.toString();
            if (!selectedInputCounts.contains(inputStr)) {
              return false;
            }
          }
          
          // Output count filter
          if (selectedOutputCounts.isNotEmpty && 
              product.additionalInfo.containsKey('analogOutputs')) {
            final int outputs = product.additionalInfo['analogOutputs'] as int;
            final String outputStr = outputs.toString();
            if (!selectedOutputCounts.contains(outputStr)) {
              return false;
            }
          }
          
          // Network type filter (simplified for now)
          if (selectedNetworkTypes.isNotEmpty && 
              product.additionalInfo.containsKey('networkIO')) {
            final int networkIO = product.additionalInfo['networkIO'] as int;
            String networkType = '';
            if (networkIO > 0) {
              networkType = 'Network I/O';
            } else {
              networkType = 'Analog Only';
            }
            if (!selectedNetworkTypes.contains(networkType)) {
              return false;
            }
          }
        }
        
        return true;
      }).toList();
      
      // Apply sorting
      _sortProducts();
    });
  }
  
  void _sortProducts() {
    filteredProducts.sort((ProductItem a, ProductItem b) {
      switch (selectedSort) {
        case SortOption.priceLowToHigh:
          return (a.price ?? 0).compareTo(b.price ?? 0);
        case SortOption.priceHighToLow:
          return (b.price ?? 0).compareTo(a.price ?? 0);
        case SortOption.nameAToZ:
          return a.name.compareTo(b.name);
        case SortOption.nameZToA:
          return b.name.compareTo(a.name);
      }
    });
  }
  
  int _getActiveFilterCount() {
    return selectedMountTypes.length +
        selectedVenueTypes.length +
        selectedColors.length +
        selectedCoverage.length +
        selectedImpedance.length +
        selectedChannelCounts.length +
        selectedPowerRanges.length +
        selectedInputCounts.length +
        selectedOutputCounts.length +
        selectedNetworkTypes.length;
  }
  
  String _getSortLabelForOption(SortOption option) {
    switch (option) {
      case SortOption.priceLowToHigh:
        return 'Price: Low → High';
      case SortOption.priceHighToLow:
        return 'Price: High → Low';
      case SortOption.nameAToZ:
        return 'A → Z';
      case SortOption.nameZToA:
        return 'Z → A';
    }
  }
  
  void _showProductDetails(BuildContext context, ProductItem product) {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProductDetailsDialog(product: product),
    );
  }
}

/// Unified product item class that wraps all product types
class ProductItem {
  final String name;
  final String type;
  final double? price;
  final String? imageUrl;
  final String? mountType;
  final String? venueType;
  final String? color;
  final CoverageLevel? coverage;
  final ImpedanceLevel? impedance;
  final Map<String, dynamic> additionalInfo;
  
  ProductItem({
    required this.name,
    required this.type,
    this.price,
    this.imageUrl,
    this.mountType,
    this.venueType,
    this.color,
    this.coverage,
    this.impedance,
    this.additionalInfo = const <String, dynamic>{},
  });
  
  factory ProductItem.fromSpeaker(SpeakerModel speaker) {
    return ProductItem(
      name: speaker.model,
      type: 'Speaker',
      price: speaker.price,
      imageUrl: speaker.imageUrl.isNotEmpty ? speaker.imageUrl : null,
      mountType: capitalize(speaker.mountingType),
      venueType: speaker.outdoorRated ? 'Outdoor' : 'Indoor',
      color: capitalize(speaker.color), // Use the actual color field from SpeakerModel
      coverage: getCoverageFromSpl(speaker.maxSpl),
      impedance: getImpedanceLevel(speaker.nominalOhms),
      additionalInfo: <String, dynamic>{
        'maxSpl': speaker.maxSpl,
        'nominalOhms': speaker.nominalOhms,
        'hasHiZ': speaker.hasHiZ,
        'longTermRms': speaker.longTermRms,
        'ppk': speaker.ppk,
      },
    );
  }
  
  factory ProductItem.fromAmplifier(AmpModel amplifier) {
    return ProductItem(
      name: amplifier.name,
      type: 'Amplifier',
      price: null, // Amplifiers don't have price in the model
      imageUrl: amplifier.imageUrl.isNotEmpty ? amplifier.imageUrl : null,
      additionalInfo: <String, dynamic>{
        'channels': amplifier.channels,
        'peakPerChannel': amplifier.peakPerChannel,
        'totalCapacity': amplifier.totalCapacity,
      },
    );
  }
  
  factory ProductItem.fromDevice(DeviceSpec device) {
    return ProductItem(
      name: device.name,
      type: 'DSP Device',
      price: null, // Devices don't have price in the model
      imageUrl: device.imageUrl.isNotEmpty ? device.imageUrl : null,
      additionalInfo: <String, dynamic>{
        'analogInputs': device.analogInputs,
        'analogOutputs': device.analogOutputs,
        'networkIO': device.networkIO,
        'totalAnalogIO': device.totalAnalogIO,
      },
    );
  }
  
  static String capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
  
  static CoverageLevel getCoverageFromSpl(double spl) {
    if (spl < 100) return CoverageLevel.low;
    if (spl < 110) return CoverageLevel.mid;
    return CoverageLevel.high;
  }
  
  static ImpedanceLevel getImpedanceLevel(double ohms) {
    return ohms <= 4 ? ImpedanceLevel.low : ImpedanceLevel.high;
  }
}

/// Clean modern product card with device specs
class CleanProductCard extends StatelessWidget {
  final ProductItem product;
  final VoidCallback? onTap;
  
  const CleanProductCard({
    super.key, 
    required this.product,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          // Product image
          Expanded(
            flex: 3, // Increased from 1 to give more space to image
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(12), // Increased padding for better image display
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.imageUrl!.startsWith('assets/')
                          ? Image.asset(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                // Try fallback to default image
                                return Image.asset(
                                  'assets/images/default_image.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                                      Center(
                                        child: Icon(
                                          _getProductIcon(),
                                          size: 32,
                                          color: const Color(0xFFBDBDBD),
                                        ),
                                      ),
                                );
                              },
                            )
                          : Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: _getTypeColor(),
                                  ),
                                );
                              },
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                                  Center(
                                    child: Icon(
                                      _getProductIcon(),
                                      size: 32,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                  ),
                            ),
                    )
                  : Center(
                      child: Icon(
                        _getProductIcon(),
                        size: 32,
                        color: const Color(0xFFBDBDBD),
                      ),
                    ),
            ),
          ),
          // Product details with specs
          Expanded(
            flex: 2, // Reduced from 4 to balance with larger image area
            child: Padding(
              padding: const EdgeInsets.all(12), // Increased padding for better spacing
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13, // Slightly reduced for better fit
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                    const SizedBox(height: 4), // Increased spacing
                    
                    // Product type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        product.type,
                        style: const TextStyle(
                          fontSize: 10, // Reduced from 14 to prevent overflow
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6), // Increased spacing
                    
                    // Device specs - using Flexible instead of Expanded
                    Flexible(
                      child: _buildDeviceSpecs(),
                    ),
                    
                    const SizedBox(height: 4), // Add spacing before price
                    
                    // Price
                    if (product.price != null)
                      Text(
                        '\$${product.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12, // Increased from 10
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0EA5E9),
                        ),
                      )
                    else
                      const Text(
                        'Contact for pricing',
                        style: TextStyle(
                          fontSize: 10, // Reduced from 12 to prevent overflow
                          color: Color(0xFF757575),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceSpecs() {
    final List<Widget> specs = <Widget>[];
    
    // Add specs based on product type
    switch (product.type) {
      case 'Speaker':
        if (product.additionalInfo.containsKey('maxSpl')) {
          specs.add(_buildSpecItem(
            Icons.volume_up_outlined, 
            '${product.additionalInfo['maxSpl']} dB',
          ));
        }
        if (product.additionalInfo.containsKey('nominalOhms')) {
          specs.add(_buildSpecItem(
            Icons.electrical_services_outlined, 
            '${product.additionalInfo['nominalOhms']}Ω',
          ));
        }
        if (product.mountType != null) {
          specs.add(_buildSpecItem(
            Icons.install_desktop_outlined, 
            product.mountType!,
          ));
        }
        break;
        
      case 'Amplifier':
        if (product.additionalInfo.containsKey('channels')) {
          specs.add(_buildSpecItem(
            Icons.linear_scale_outlined, 
            '${product.additionalInfo['channels']} Ch',
          ));
        }
        if (product.additionalInfo.containsKey('peakPerChannel')) {
          specs.add(_buildSpecItem(
            Icons.power_outlined, 
            '${product.additionalInfo['peakPerChannel']}W',
          ));
        }
        break;
        
      case 'DSP Device':
        if (product.additionalInfo.containsKey('analogInputs')) {
          specs.add(_buildSpecItem(
            Icons.input_outlined, 
            '${product.additionalInfo['analogInputs']} In',
          ));
        }
        if (product.additionalInfo.containsKey('analogOutputs')) {
          specs.add(_buildSpecItem(
            Icons.output_outlined, 
            '${product.additionalInfo['analogOutputs']} Out',
          ));
        }
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: specs.take(2).toList(), // Reduced from 3 to 2 specs
    );
  }
  
  Widget _buildSpecItem(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF757575),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF616161),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getProductIcon() {
    switch (product.type) {
      case 'Speaker':
        return Icons.speaker_outlined;
      case 'Amplifier':
        return Icons.settings_input_component_outlined;
      case 'DSP Device':
        return Icons.tune_outlined;
      default:
        return Icons.device_unknown_outlined;
    }
  }
  
  Color _getTypeColor() {
    switch (product.type) {
      case 'Speaker':
        return const Color(0xFF0EA5E9);
      case 'Amplifier':
        return const Color(0xFFF59E0B);
      case 'DSP Device':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

/// Detailed product information dialog
class ProductDetailsDialog extends StatelessWidget {
  final ProductItem product;
  
  const ProductDetailsDialog({super.key, required this.product});
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header with close button
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Product type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTypeColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.type,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Product image
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16), // Add padding for better image display
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: product.imageUrl!.startsWith('assets/')
                                  ? Image.asset(
                                      product.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                        // Try fallback to default image
                                        return Image.asset(
                                          'assets/images/default_image.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                                              Center(
                                                child: Icon(
                                                  _getProductIcon(),
                                                  size: 100,
                                                  color: const Color(0xFFBDBDBD),
                                                ),
                                              ),
                                        );
                                      },
                                    )
                                  : Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.contain,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 3,
                                            color: _getTypeColor(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                                          Center(
                                            child: Icon(
                                              _getProductIcon(),
                                              size: 100,
                                              color: const Color(0xFFBDBDBD),
                                            ),
                                          ),
                                    ),
                            )
                          : Center(
                              child: Icon(
                                _getProductIcon(),
                                size: 100,
                                color: const Color(0xFFBDBDBD),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Product specifications
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Specifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildDetailedSpecs(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Price and action buttons
            Row(
              children: <Widget>[
                if (product.price != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${product.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Contact for pricing',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Add to project or cart functionality
                  },
                  icon: const Icon(Icons.add_outlined),
                  label: const Text('Add to Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailedSpecs() {
    final Map<String, String> specs = <String, String>{};
    
    // Add specs based on product type
    switch (product.type) {
      case 'Speaker':
        if (product.additionalInfo.containsKey('maxSpl')) {
          specs['Max SPL'] = '${product.additionalInfo['maxSpl']} dB';
        }
        if (product.additionalInfo.containsKey('nominalOhms')) {
          specs['Impedance'] = '${product.additionalInfo['nominalOhms']}Ω';
        }
        if (product.additionalInfo.containsKey('longTermRms')) {
          specs['Long Term RMS'] = '${product.additionalInfo['longTermRms']}W';
        }
        if (product.additionalInfo.containsKey('ppk')) {
          specs['Peak Power'] = '${product.additionalInfo['ppk']}W';
        }
        if (product.mountType != null) {
          specs['Mount Type'] = product.mountType!;
        }
        if (product.venueType != null) {
          specs['Venue Type'] = product.venueType!;
        }
        if (product.color != null) {
          specs['Color'] = product.color!;
        }
        if (product.additionalInfo.containsKey('hasHiZ')) {
          specs['Hi-Z Support'] = product.additionalInfo['hasHiZ'] ? 'Yes' : 'No';
        }
        break;
        
      case 'Amplifier':
        if (product.additionalInfo.containsKey('channels')) {
          specs['Channels'] = '${product.additionalInfo['channels']}';
        }
        if (product.additionalInfo.containsKey('peakPerChannel')) {
          specs['Peak Power per Channel'] = '${product.additionalInfo['peakPerChannel']}W';
        }
        if (product.additionalInfo.containsKey('totalCapacity')) {
          specs['Total Capacity'] = '${product.additionalInfo['totalCapacity']}W';
        }
        break;
        
      case 'DSP Device':
        if (product.additionalInfo.containsKey('analogInputs')) {
          specs['Analog Inputs'] = '${product.additionalInfo['analogInputs']}';
        }
        if (product.additionalInfo.containsKey('analogOutputs')) {
          specs['Analog Outputs'] = '${product.additionalInfo['analogOutputs']}';
        }
        if (product.additionalInfo.containsKey('networkIO')) {
          specs['Network I/O'] = '${product.additionalInfo['networkIO']}';
        }
        if (product.additionalInfo.containsKey('totalAnalogIO')) {
          specs['Total Analog I/O'] = '${product.additionalInfo['totalAnalogIO']}';
        }
        break;
    }
    
    return SingleChildScrollView(
      child: Column(
        children: specs.entries.map((MapEntry<String, String> entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  IconData _getProductIcon() {
    switch (product.type) {
      case 'Speaker':
        return Icons.speaker_outlined;
      case 'Amplifier':
        return Icons.settings_input_component_outlined;
      case 'DSP Device':
        return Icons.tune_outlined;
      default:
        return Icons.device_unknown_outlined;
    }
  }
  
  Color _getTypeColor() {
    switch (product.type) {
      case 'Speaker':
        return const Color(0xFF0EA5E9);
      case 'Amplifier':
        return const Color(0xFFF59E0B);
      case 'DSP Device':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
