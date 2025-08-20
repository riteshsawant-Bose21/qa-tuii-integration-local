import 'package:flutter/material.dart';

import '../../../../core/models/products_data.dart';

class DevicesCatalogWidget extends StatefulWidget {
  /// Data lists for each section
  final List<SpeakerData> speakers;
  final List<SourceData> sources;
  final List<ControllerData> controllers;
  final List<RackData> racks;




  const DevicesCatalogWidget({
    super.key,
    this.speakers = SpeakerData.demoSpeakers,
    this.sources = SourceData.demoSources,
    this.controllers = ControllerData.demoControllers,
    this.racks = RackData.demoRacks,
  });

  @override
  State<DevicesCatalogWidget> createState() => _DevicesCatalogWidgetState();
}

class _DevicesCatalogWidgetState extends State<DevicesCatalogWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primaryText = Color(0xCC000000);
  static const Color secondaryText = Color(0x4D000000);
  static const Color accentColor = Color(0xFF146C94);
  static const Color speakerColor = Color(0xFF80C7FF);
  static const Color sourceColor = Color(0xFF80C7FF);
  static const Color controllerColor = Color(0xFF80C7FF);
  static const Color rackColor = Color(0xFF80C7FF);
  static const double fsSmall = 11;
  static const double fsRegular = 12;
  static const double fsMedium = 13;

  final GlobalKey _draggableKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(width: 1, color: Color(0xFFD5D5D5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: _buildHeader(),
              children: <Widget>[
                _buildSearchField(),
                _buildDeviceList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.devices_outlined,
            size: 18,
            color: accentColor,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Product Query",
              style: TextStyle(
                fontSize: fsMedium,
                color: primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search devices...',
          hintStyle: const TextStyle(
            fontSize: fsRegular,
            color: secondaryText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: secondaryText,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(
                      Icons.clear,
                      size: 18,
                      color: secondaryText,
                    ),
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    // final List<HardwareComponent> filteredComponents = _filterComponents();

    //
    // if (filteredComponents.isEmpty) {
    //   return Container(
    //     padding: const EdgeInsets.all(32),
    //     child: Column(
    //       children: <Widget>[
    //         Icon(
    //           Icons.search_off,
    //           size: 48,
    //           color: Colors.grey[300],
    //         ),
    //         const SizedBox(height: 16),
    //         Text(
    //           _searchQuery.isEmpty ? 'No devices found' : 'No devices match your search',
    //           style: const TextStyle(
    //             fontSize: fsRegular,
    //             color: secondaryText,
    //           ),
    //         ),
    //       ],
    //     ),
    //   );
    // }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),

      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildCategorySection('Speakers', widget.speakers, speakerColor, Icons.speaker_outlined),
            _buildCategorySection('Sources', widget.sources, sourceColor, Icons.input_outlined),
            _buildCategorySection('Controllers', widget.controllers, controllerColor, Icons.settings_remote_outlined),
            _buildCategorySection('Racks', widget.racks, rackColor, Icons.dns_outlined),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String title, List<dynamic> components, Color categoryColor, IconData icon) {
    if (components.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          const BoxShadow(
            color: Color(0xFFD5D5D5),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _searchQuery.isNotEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          collapsedIconColor: primaryText,
          iconColor: categoryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: fsRegular,
                    color: primaryText,
                    fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  components.length.toString(),
                  style: const TextStyle(
                    fontSize: fsSmall,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: components.map((dynamic component) => _buildDeviceItem(component, categoryColor)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(DeviceComponent component, Color categoryColor) {
    return Draggable<DeviceComponent>(
      data: component,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: DraggingListItem(
        dragKey: _draggableKey,
        assetPath: component.assetPath,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: <Widget>[
            // Device Image
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  component.assetPath.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          component.assetPath,

                          errorBuilder:
                              (BuildContext context, Object error, StackTrace? stackTrace) => Icon(
                                Icons.device_unknown,
                                size: 12,
                                color: categoryColor,
                              ),
                        ),
                      )
                      : Icon(
                        Icons.device_unknown,
                        size: 12,
                        color: categoryColor,
                      ),
            ),
            const SizedBox(width: 12),

            // Device Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  component.name,
                  style: const TextStyle(
                    fontSize: fsRegular,
                    color: primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Price
                Text(
                  '\$${component.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: fsSmall,
                    color: primaryText,
                  ),
                    overflow: TextOverflow.ellipsis
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }

  String? getImagePath(dynamic component) {
    if (component is SpeakerData) {
      return component.assetPath;
    } else if (component is SourceData) {
      return component.assetPath;
    } else if (component is ControllerData) {
      return component.assetPath;
    } else if (component is RackData) {
      return component.assetPath;
    }
    return null;
  }

  double getPrice(dynamic component) {
    if (component is SpeakerData) {
      return component.price;
    } else if (component is SourceData) {
      return component.price;
    } else if (component is ControllerData) {
      return component.price;
    } else if (component is RackData) {
      return component.price;
    }
    return 0.0;
  }

  // List<HardwareComponent> _filterComponents() {
  //   if (_searchQuery.isEmpty) return widget.components;
  //
  //   return widget.components.where((HardwareComponent component) {
  //     return component.name.toLowerCase().contains(_searchQuery) ||
  //         component.hardwareName.toLowerCase().contains(_searchQuery) ||
  //         (component.locationEntity.name?.toLowerCase().contains(_searchQuery) ?? false);
  //   }).toList();
  // }
}

class DraggingListItem extends StatelessWidget {
  const DraggingListItem({
    super.key,
    required this.dragKey,
    required this.assetPath,
  });

  final GlobalKey dragKey;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: ClipRRect(
        key: dragKey,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 50,
          width: 50,
          child: Opacity(
            opacity: 0.85,
            child: Image.asset(
              assetPath,
              height: 50,
              width: 50,

              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) => const Icon(
                    Icons.device_unknown,
                    size: 12,
                    color: Color(0xFF80C7FF),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
