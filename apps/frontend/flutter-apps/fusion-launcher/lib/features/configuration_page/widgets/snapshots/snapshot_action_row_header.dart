import 'package:flutter/material.dart';

class SceneActionHeader extends StatelessWidget {
  const SceneActionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.grey.shade200,
      child: const Row(
        children: <Widget>[
          _HeaderCell("Action Type"),
          _HeaderCell("Action Item"),
          _HeaderCell("Param / Action"),
          _HeaderCell("Value"),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}
