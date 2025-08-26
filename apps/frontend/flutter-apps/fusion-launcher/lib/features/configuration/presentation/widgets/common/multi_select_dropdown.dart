// import 'package:flutter/material.dart';
//
// class MultiSelectItem {
//   final String value;
//   final String label;
//   final IconData? icon;
//   double dbValue;
//
//   MultiSelectItem({
//     required this.value,
//     required this.label,
//     this.icon,
//     this.dbValue = -40.0,
//   });
// }
//
// class CustomMultiSelectDropdown extends StatefulWidget {
//   final List<MultiSelectItem> items;
//   final List<MultiSelectItem> selectedItems;
//   final Function(List<MultiSelectItem>) onSelectionChanged;
//   final String hint;
//   final double maxHeight;
//
//   const CustomMultiSelectDropdown({
//     super.key,
//     required this.items,
//     required this.selectedItems,
//     required this.onSelectionChanged,
//     this.hint = 'Audio Devices',
//     this.maxHeight = 200,
//   });
//
//   @override
//   State<CustomMultiSelectDropdown> createState() => _CustomMultiSelectDropdownState();
// }
//
// class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> with TickerProviderStateMixin {
//   final LayerLink _layerLink = LayerLink();
//   final TextEditingController _searchController = TextEditingController();
//   final GlobalKey _headerKey = GlobalKey();
//
//   OverlayEntry? _overlayEntry;
//   bool _isDropdownOpen = false;
//   bool _isExpanded = false;
//   List<MultiSelectItem> _filteredItems = [];
//
//   late AnimationController _expandController;
//   late Animation<double> _expandAnimation;
//   late AnimationController _overlayController;
//   late Animation<double> _overlayAnimation;
//   late Animation<double> _overlayScaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _filteredItems = List.from(widget.items);
//     _searchController.addListener(_onSearchChanged);
//
//     _expandController = AnimationController(
//       duration: const Duration(milliseconds: 250),
//       vsync: this,
//     );
//     _expandAnimation = CurvedAnimation(
//       parent: _expandController,
//       curve: Curves.easeOutCubic,
//     );
//
//     // Optimized overlay animation with shorter duration and better curve
//     _overlayController = AnimationController(
//       duration: const Duration(milliseconds: 150), // Reduced from 200ms
//       vsync: this,
//     );
//
//     // Use different curves for fade and scale for smoother feel
//     _overlayAnimation = CurvedAnimation(
//       parent: _overlayController,
//       curve: Curves.easeOut, // Simpler curve for opacity
//     );
//
//     _overlayScaleAnimation = CurvedAnimation(
//       parent: _overlayController,
//       curve: Curves.easeOutBack, // More dramatic curve for scale
//     );
//
//     // Start expanded if there are selected items
//     if (widget.selectedItems.isNotEmpty) {
//       _isExpanded = true;
//       _expandController.forward();
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _expandController.dispose();
//     _overlayController.dispose();
//     _removeOverlay();
//     super.dispose();
//   }
//
//   void _onSearchChanged() {
//     _filteredItems = widget.items
//         .where((item) =>
//         item.label.toLowerCase().contains(_searchController.text.toLowerCase()))
//         .toList();
//     _updateOverlay();
//   }
//
//   void _toggleExpanded() {
//     if (widget.selectedItems.isEmpty) return;
//
//     setState(() {
//       _isExpanded = !_isExpanded;
//     });
//     if (_isExpanded) {
//       _expandController.forward();
//     } else {
//       _expandController.reverse();
//     }
//   }
//
//   void _toggleDropdown() {
//     if (_isDropdownOpen) {
//       _removeOverlay();
//     } else {
//       _showOverlay();
//     }
//   }
//
//   void _showOverlay() {
//     _overlayEntry = _createOverlayEntry();
//     Overlay.of(context).insert(_overlayEntry!);
//     _overlayController.forward();
//     setState(() {
//       _isDropdownOpen = true;
//     });
//   }
//
//   void _removeOverlay() {
//     if (_overlayEntry != null) {
//       _overlayController.reverse().then((_) {
//         _overlayEntry?.remove();
//         _overlayEntry = null;
//       });
//     }
//     setState(() {
//       _isDropdownOpen = false;
//     });
//     _searchController.clear();
//   }
//
//   void _updateOverlay() {
//     if (_overlayEntry != null) {
//       _overlayEntry!.markNeedsBuild();
//     }
//   }
//
//   OverlayEntry _createOverlayEntry() {
//     return OverlayEntry(
//       builder: (context) {
//         final RenderBox? renderBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
//         if (renderBox == null) return const SizedBox();
//
//         final position = renderBox.localToGlobal(Offset.zero);
//         final size = renderBox.size;
//         final screenHeight = MediaQuery.of(context).size.height;
//
//         final spaceBelow = screenHeight - position.dy - size.height;
//         final spaceAbove = position.dy;
//         final showAbove = spaceBelow < widget.maxHeight && spaceAbove > spaceBelow;
//
//         return Positioned(
//           left: position.dx,
//           top: showAbove ? position.dy - widget.maxHeight - 5 : position.dy + size.height + 5,
//           width: size.width,
//           child: AnimatedBuilder(
//             animation: _overlayController,
//             builder: (context, child) {
//               return Transform.scale(
//                 scale: 0.95 + (0.05 * _overlayScaleAnimation.value), // Start from 95% scale
//                 alignment: showAbove ? Alignment.bottomCenter : Alignment.topCenter,
//                 child: Opacity(
//                   opacity: _overlayAnimation.value,
//                   child: Material(
//                     elevation: 8, // Reduced elevation for better performance
//                     shadowColor: Colors.black.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(12),
//                     color: Colors.transparent,
//                     child: Container(
//                       constraints: BoxConstraints(maxHeight: widget.maxHeight),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: Colors.grey.shade200),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.06), // Reduced shadow opacity
//                             blurRadius: 16,
//                             offset: const Offset(0, 6),
//                           ),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             // Search Field
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade50,
//                                 borderRadius: const BorderRadius.only(
//                                   topLeft: Radius.circular(12),
//                                   topRight: Radius.circular(12),
//                                 ),
//                               ),
//                               child: TextField(
//                                 controller: _searchController,
//                                 style: const TextStyle(fontSize: 13),
//                                 decoration: InputDecoration(
//                                   hintText: 'Search devices...',
//                                   hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                                   prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade500),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                   isDense: true,
//                                 ),
//                               ),
//                             ),
//                             // Items List
//                             Flexible(
//                               child: Container(
//                                 decoration: const BoxDecoration(
//                                   borderRadius: BorderRadius.only(
//                                     bottomLeft: Radius.circular(12),
//                                     bottomRight: Radius.circular(12),
//                                   ),
//                                 ),
//                                 child: ListView.builder(
//                                   padding: EdgeInsets.zero,
//                                   shrinkWrap: true,
//                                   physics: const ClampingScrollPhysics(), // Better scroll performance
//                                   itemCount: _filteredItems.length,
//                                   itemBuilder: (context, index) {
//                                     final item = _filteredItems[index];
//                                     final isSelected = widget.selectedItems
//                                         .any((selected) => selected.value == item.value);
//
//                                     return Material(
//                                       color: Colors.transparent,
//                                       child: InkWell(
//                                         onTap: () => _toggleSelection(item),
//                                         child: Container(
//                                           margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                                           decoration: BoxDecoration(
//                                             borderRadius: BorderRadius.circular(8),
//                                             color: isSelected ? Colors.blue.shade50 : Colors.transparent,
//                                           ),
//                                           child: Row(
//                                             children: [
//                                               AnimatedContainer(
//                                                 duration: const Duration(milliseconds: 150), // Reduced animation duration
//                                                 curve: Curves.easeOutCubic,
//                                                 width: 18,
//                                                 height: 18,
//                                                 decoration: BoxDecoration(
//                                                   borderRadius: BorderRadius.circular(4),
//                                                   color: isSelected ? Colors.blue : Colors.transparent,
//                                                   border: Border.all(
//                                                     color: isSelected ? Colors.blue : Colors.grey.shade400,
//                                                     width: 2,
//                                                   ),
//                                                 ),
//                                                 child: isSelected
//                                                     ? const Icon(Icons.check, size: 12, color: Colors.white)
//                                                     : null,
//                                               ),
//                                               const SizedBox(width: 12),
//                                               if (item.icon != null) ...[
//                                                 Icon(item.icon, size: 16, color: Colors.grey.shade600),
//                                                 const SizedBox(width: 8),
//                                               ],
//                                               Expanded(
//                                                 child: Text(
//                                                   item.label,
//                                                   style: TextStyle(
//                                                     fontSize: 13,
//                                                     color: isSelected ? Colors.blue.shade700 : Colors.black87,
//                                                     fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
//
//   void _toggleSelection(MultiSelectItem item) {
//     List<MultiSelectItem> newSelection = List.from(widget.selectedItems);
//
//     final existingIndex = newSelection.indexWhere((selected) => selected.value == item.value);
//
//     if (existingIndex >= 0) {
//       newSelection.removeAt(existingIndex);
//     } else {
//       newSelection.add(MultiSelectItem(
//         value: item.value,
//         label: item.label,
//         icon: item.icon,
//         dbValue: -40.0,
//       ));
//     }
//
//     widget.onSelectionChanged(newSelection);
//     _updateOverlay();
//
//     // Auto-expand if first item is selected
//     if (newSelection.isNotEmpty && !_isExpanded) {
//       setState(() {
//         _isExpanded = true;
//       });
//       _expandController.forward();
//     }
//   }
//
//   void _updateDbValue(int index, double value) {
//     List<MultiSelectItem> updatedSelection = List.from(widget.selectedItems);
//     updatedSelection[index].dbValue = value;
//     widget.onSelectionChanged(updatedSelection);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         children: [
//           // Header with Add Button
//           Container(
//             key: _headerKey,
//             child: Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: widget.selectedItems.isEmpty ? null : _toggleExpanded,
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                   decoration: BoxDecoration(
//                     color: widget.selectedItems.isEmpty ? Colors.grey.shade50 : Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: widget.selectedItems.isEmpty ? Colors.grey.shade200 : Colors.blue.shade100,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Icon(
//                           Icons.devices_rounded,
//                           size: 18,
//                           color: widget.selectedItems.isEmpty ? Colors.grey.shade600 : Colors.blue.shade700,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.hint,
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: widget.selectedItems.isEmpty ? Colors.grey.shade700 : Colors.blue.shade700,
//                               ),
//                             ),
//                             if (widget.selectedItems.isNotEmpty)
//                               Text(
//                                 '${widget.selectedItems.length} device${widget.selectedItems.length > 1 ? 's' : ''} selected',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.blue.shade600,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                       // Add Button
//                       Material(
//                         color: Colors.transparent,
//                         child: InkWell(
//                           onTap: _toggleDropdown,
//                           borderRadius: BorderRadius.circular(8),
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 150), // Reduced duration
//                             curve: Curves.easeOutCubic,
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: _isDropdownOpen ? Colors.blue : Colors.blue.shade100,
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: _isDropdownOpen ? [
//                                 BoxShadow(
//                                   color: Colors.blue.withOpacity(0.25), // Reduced shadow opacity
//                                   blurRadius: 6,
//                                   offset: const Offset(0, 2),
//                                 ),
//                               ] : null,
//                             ),
//                             child: AnimatedRotation(
//                               turns: _isDropdownOpen ? 0.125 : 0,
//                               duration: const Duration(milliseconds: 150),
//                               curve: Curves.easeOutCubic,
//                               child: Icon(
//                                 Icons.add_rounded,
//                                 size: 20,
//                                 color: _isDropdownOpen ? Colors.white : Colors.blue.shade700,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       // Expand/Collapse Arrow (only show if there are selected items)
//                       if (widget.selectedItems.isNotEmpty) ...[
//                         const SizedBox(width: 8),
//                         AnimatedRotation(
//                           turns: _isExpanded ? 0.5 : 0,
//                           duration: const Duration(milliseconds: 250),
//                           curve: Curves.easeOutCubic,
//                           child: Icon(
//                             Icons.keyboard_arrow_down_rounded,
//                             size: 22,
//                             color: Colors.blue.shade700,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           // Expandable Selected Items Content
//           if (widget.selectedItems.isNotEmpty)
//             SizeTransition(
//               sizeFactor: _expandAnimation,
//               child: Container(
//                 padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                 child: Column(
//                   children: widget.selectedItems.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final item = entry.value;
//
//                     return Container(
//                       margin: const EdgeInsets.only(top: 8),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.grey.shade200),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.02),
//                             blurRadius: 4,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(12),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 if (item.icon != null) ...[
//                                   Container(
//                                     padding: const EdgeInsets.all(6),
//                                     decoration: BoxDecoration(
//                                       color: Colors.blue.shade100,
//                                       borderRadius: BorderRadius.circular(6),
//                                     ),
//                                     child: Icon(
//                                       item.icon,
//                                       size: 16,
//                                       color: Colors.blue.shade700,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                 ],
//                                 Expanded(
//                                   child: Text(
//                                     item.label,
//                                     style: const TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                 ),
//                                 Material(
//                                   color: Colors.transparent,
//                                   child: InkWell(
//                                     onTap: () => _toggleSelection(item),
//                                     borderRadius: BorderRadius.circular(6),
//                                     child: Container(
//                                       padding: const EdgeInsets.all(6),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.shade100,
//                                         borderRadius: BorderRadius.circular(6),
//                                       ),
//                                       child: Icon(
//                                         Icons.close_rounded,
//                                         size: 16,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 10),
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade100,
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: Text(
//                                     'Volume',
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       color: Colors.grey.shade700,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 3,
//                                       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
//                                       overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
//                                       activeTrackColor: Colors.blue,
//                                       inactiveTrackColor: Colors.grey.shade300,
//                                       thumbColor: Colors.blue,
//                                       overlayColor: Colors.blue.withOpacity(0.2),
//                                     ),
//                                     child: Slider(
//                                       value: item.dbValue,
//                                       min: -80.0,
//                                       max: 0.0,
//                                       onChanged: (value) => _updateDbValue(index, value),
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue.shade50,
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: Text(
//                                     '${item.dbValue.round()}dB',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.blue.shade700,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// // Example usage widget
// class MultiSelectExample extends StatefulWidget {
//   @override
//   _MultiSelectExampleState createState() => _MultiSelectExampleState();
// }
//
// class _MultiSelectExampleState extends State<MultiSelectExample> {
//   List<MultiSelectItem> selectedItems = [];
//
//   final List<MultiSelectItem> allItems = [
//     MultiSelectItem(value: '1', label: 'Built-in Speakers', icon: Icons.speaker_rounded),
//     MultiSelectItem(value: '2', label: 'Bluetooth Headphones', icon: Icons.headphones_rounded),
//     MultiSelectItem(value: '3', label: 'USB Microphone', icon: Icons.mic_rounded),
//     MultiSelectItem(value: '4', label: 'External Monitor', icon: Icons.monitor_rounded),
//     MultiSelectItem(value: '5', label: 'Wireless Earbuds', icon: Icons.earbuds_rounded),
//     MultiSelectItem(value: '6', label: 'Gaming Headset', icon: Icons.headset_mic_rounded),
//     MultiSelectItem(value: '7', label: 'Audio Interface', icon: Icons.audio_file_rounded),
//     MultiSelectItem(value: '8', label: 'Line Input', icon: Icons.input_rounded),
//     MultiSelectItem(value: '9', label: 'HDMI Audio', icon: Icons.tv_rounded),
//     MultiSelectItem(value: '10', label: 'Sound Card', icon: Icons.memory_rounded),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         title: const Text('Audio Device Selector'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//         elevation: 0,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(
//             color: Colors.grey.shade200,
//             height: 1,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Configure Audio',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey.shade800,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Select devices and adjust volume levels',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
//             CustomMultiSelectDropdown(
//               items: allItems,
//               selectedItems: selectedItems,
//               onSelectionChanged: (items) {
//                 setState(() {
//                   selectedItems = items;
//                 });
//               },
//               hint: 'Audio Devices',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }