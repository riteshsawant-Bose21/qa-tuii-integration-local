// import 'package:flutter/material.dart';
//
// import '../../../../../core/constants.dart';
// import '../processing/processing_chain_widget.dart';
// import '../zones/circuit_widget.dart';
//
// class SubZoneWidget extends StatefulWidget {
//   final SubZone subZone;
//   final void Function(SubZone) onSubZoneChanged;
//   final VoidCallback onDelete;
//
//   const SubZoneWidget({
//     super.key,
//     required this.subZone,
//     required this.onSubZoneChanged,
//     required this.onDelete,
//   });
//
//   @override
//   _SubZoneWidgetState createState() => _SubZoneWidgetState();
// }
//
// class _SubZoneWidgetState extends State<SubZoneWidget> {
//   bool _isExpanded = false;
//
//   @override
//   Widget build(BuildContext ctx) {
//     return Card(
//       elevation: 0,
//       color: AppColors.cardSoft,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(6),
//         side: const BorderSide(color: AppColors.borderSoft),
//       ),
//       child: Column(
//         children: <Widget>[
//           // Header
//           InkWell(
//             onTap: () => setState(() => _isExpanded = !_isExpanded),
//             borderRadius: BorderRadius.circular(6),
//             child: Padding(
//               padding: const EdgeInsets.all(8),
//               child: Row(
//                 children: <Widget>[
//                   Icon(
//                     _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
//                     size: 16,
//                     color: AppColors.warningSoft,
//                   ),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: TextFormField(
//                       initialValue: widget.subZone.name,
//                       decoration: const InputDecoration(isDense: true, border: InputBorder.none),
//                       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//                       onChanged: (String v) => widget.onSubZoneChanged(widget.subZone.copyWith(name: v)),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: AppColors.warningSoft.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       '${widget.subZone.circuits.length}',
//                       style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete_outline, color: AppColors.errorSoft, size: 16),
//                     onPressed: widget.onDelete,
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Expanded body
//           if (_isExpanded)
//             Padding(
//               padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: <Widget>[
//                   ProcessingChainWidget(
//                     processingBlocks: widget.subZone.processingBlocks,
//                     onProcessingChainChanged:
//                         (ProcessingChainEntity chain) => widget.onSubZoneChanged(
//                           widget.subZone.copyWith(processingBlocks: chain),
//                         ),
//                   ),
//                   const SizedBox(height: 8),
//
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: <Widget>[
//                       Text('Circuits: ${widget.subZone.circuits.length}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
//                       ElevatedButton.icon(
//                         onPressed: _addCircuit,
//                         icon: const Icon(Icons.add, size: 14),
//                         label: const Text('Add Circuit', style: TextStyle(fontSize: 11)),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFB8956A),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           minimumSize: const Size(0, 28),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//
//                   // Circuit list
//                   ...widget.subZone.circuits.asMap().entries.map((MapEntry<int, Circuit> e) {
//                     final int idx = e.key;
//                     final Circuit ckt = e.value;
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 4),
//                       child: CircuitWidget(
//                         circuit: ckt,
//                         onCircuitChanged: (Circuit updated) {
//                           final List<Circuit> list = <Circuit>[...widget.subZone.circuits]..[idx] = updated;
//                           widget.onSubZoneChanged(widget.subZone.copyWith(circuits: list));
//                         },
//                         onDelete: () {
//                           final List<Circuit> list = <Circuit>[...widget.subZone.circuits]..removeAt(idx);
//                           widget.onSubZoneChanged(widget.subZone.copyWith(circuits: list));
//                         },
//                       ),
//                     );
//                   }),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   void _addCircuit() {
//     final Circuit newCircuit = Circuit(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       name: 'Circuit ${widget.subZone.circuits.length + 1}',
//       gain: 0.0,
//     );
//     widget.onSubZoneChanged(widget.subZone.copyWith(circuits: <Circuit>[...widget.subZone.circuits, newCircuit]));
//   }
// }
