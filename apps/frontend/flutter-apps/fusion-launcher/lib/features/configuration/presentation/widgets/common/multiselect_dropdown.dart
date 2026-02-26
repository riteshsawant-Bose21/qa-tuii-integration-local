import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MultiselectDropdown extends StatefulWidget {
  final List<Source> allSources;

  const MultiselectDropdown({super.key, required this.allSources});

  @override
  State<MultiselectDropdown> createState() => _MultiselectDropdownState();
}

class _MultiselectDropdownState extends State<MultiselectDropdown> {
  final List<Source> _selectedItems = <Source>[];
  final TextEditingController _searchController = TextEditingController();
  final Map<Source, double> _selectedItemsWithValues = <Source, double>{};
  List<Source> _filteredItems = <Source>[];
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = List<Source>.from(widget.allSources);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.allSources.where((Source item) => item.name.toLowerCase().contains(query)).toList();
    });
  }

  void _toggleItem(Source item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
      if (!_isDropdownOpen) {
        _searchController.clear();
        _filteredItems = List<Source>.from(widget.allSources);
      }
    });
  }

  void _updateItemValue(Source item, double value) {
    setState(() {
      _selectedItemsWithValues[item] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Custom Dropdown Container
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue[400]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: <Widget>[
                // Dropdown Header
                InkWell(
                  onTap: _toggleDropdown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.add,
                          color: Colors.blue[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FusionAppText(
                            text: "Select Source",
                            style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                          ),
                        ),
                        Icon(
                          _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                ),

                // Dropdown Content
                if (_isDropdownOpen) ...<Widget>[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        // Search Field
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 16,
                                color: Colors.grey[500],
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: Colors.black54),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                            ),
                          ),
                        ),

                        // Items List
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredItems.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Source item = _filteredItems[index];
                              final bool isSelected = _selectedItems.contains(item);

                              return InkWell(
                                onTap: () => _toggleItem(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.grey[100] : Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected ? Colors.black87 : Colors.grey[400]!,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                          color: isSelected ? Colors.black87 : Colors.white,
                                        ),
                                        child:
                                            isSelected
                                                ? const Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FusionAppText(
                                          text: item.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected ? Colors.black87 : Colors.black54,
                                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Selected Items Display
          if (_selectedItems.isNotEmpty) ...<Widget>[
            //
            // const FusionAppText(text:
            //   'Audio Mix Levels:',
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.w500,
            //     color: Colors.black87,
            //   ),
            // ),
            // const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(
                    height: 1,
                    color: Colors.grey[200],
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  final Source item = _selectedItems[index];
                  final double currentValue = _selectedItemsWithValues[item] ?? -40.0;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: FusionAppText(
                                text: item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FusionAppText(
                                text: '${currentValue.toInt()} dB',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _toggleItem(item),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Slider
                        Row(
                          children: <Widget>[
                            FusionAppText(
                              text: '-80',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16,
                                  ),
                                  activeTrackColor: Colors.black87,
                                  inactiveTrackColor: Colors.grey[300],
                                  thumbColor: Colors.black87,
                                  overlayColor: Colors.black12,
                                ),
                                child: Slider(
                                  value: currentValue,
                                  min: -80.0,
                                  max: 0.0,
                                  divisions: 80,
                                  onChanged: (double value) {
                                    _updateItemValue(item, value);
                                  },
                                ),
                              ),
                            ),
                            FusionAppText(
                              text: '0',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
