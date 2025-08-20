// // lib/widgets/circuit_widget.dart
//
// import 'package:flutter/material.dart';
//
// import '../../../../../core/constants.dart';
// import '../../../../../core/models/models.dart';
//
// class CircuitWidget extends StatefulWidget {
//   final Circuit circuit;
//   final void Function(Circuit) onCircuitChanged;
//   final VoidCallback onDelete;
//
//   const CircuitWidget({
//     super.key,
//     required this.circuit,
//     required this.onCircuitChanged,
//     required this.onDelete,
//   });
//
//   @override
//   State<CircuitWidget> createState() => _CircuitWidgetState();
// }
//
// class _CircuitWidgetState extends State<CircuitWidget> {
//   void _addSpeaker() {
//     final int ts = DateTime.now().millisecondsSinceEpoch;
//     final Speaker newSpeaker = Speaker(
//       id: 'speaker_$ts',
//       name: 'Speaker ${widget.circuit.speakers.length + 1}',
//     );
//     widget.onCircuitChanged(
//       widget.circuit.copyWith(
//         speakers: <Speaker>[...widget.circuit.speakers, newSpeaker],
//       ),
//     );
//   }
//
//   void _removeSpeaker(String id) {
//     widget.onCircuitChanged(
//       widget.circuit.copyWith(
//         speakers: widget.circuit.speakers.where((Speaker s) => s.id != id).toList(),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext ctx) {
//     final Circuit c = widget.circuit;
//     return Card(
//       elevation: 0,
//       color: AppColors.cardSoft,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(4),
//         side: const BorderSide(color: AppColors.borderSoft),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(6),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             // Title row: editable circuit name + add/delete buttons
//             Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextFormField(
//                     initialValue: c.name,
//                     decoration: const InputDecoration(
//                       isDense: true,
//                       border: InputBorder.none,
//                       hintText: 'Circuit Name',
//                     ),
//                     style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//                     onChanged: (String v) => widget.onCircuitChanged(c.copyWith(name: v)),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.speaker, size: 16),
//                   onPressed: _addSpeaker,
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                   tooltip: 'Add Speaker',
//                 ),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.delete_outline,
//                     color: Colors.redAccent,
//                     size: 16,
//                   ),
//                   onPressed: widget.onDelete,
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
//                 ),
//               ],
//             ),
//
//             // const SizedBox(height: 6),
//             //
//             // // Gain row
//             // Row(
//             //   children: <Widget>[
//             //     Expanded(
//             //       flex: 2,
//             //       child: TextFormField(
//             //         initialValue: c.gain.toString(),
//             //         decoration: const InputDecoration(
//             //           labelText: 'Gain (dB)',
//             //           border: OutlineInputBorder(),
//             //           isDense: true,
//             //           labelStyle: TextStyle(fontSize: 11),
//             //           contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             //         ),
//             //         style: const TextStyle(fontSize: 11),
//             //         keyboardType: TextInputType.number,
//             //         onChanged: (String v) {
//             //           final double g = double.tryParse(v) ?? 0.0;
//             //           widget.onCircuitChanged(c.copyWith(gain: g));
//             //         },
//             //       ),
//             //     ),
//             //   ],
//             // ),
//             const SizedBox(height: 8),
//
//             // Speakers chips
//             Wrap(
//               spacing: 6,
//               runSpacing: 4,
//               children:
//                   c.speakers.map((Speaker s) {
//                     return Chip(
//                       label: Text(s.name, style: const TextStyle(fontSize: 11)),
//                       onDeleted: () => _removeSpeaker(s.id),
//                     );
//                   }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
