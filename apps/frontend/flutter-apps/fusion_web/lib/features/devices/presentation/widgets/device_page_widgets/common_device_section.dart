import 'package:flutter/material.dart';

class CommonDeviceSection extends StatelessWidget {
  final String? title;
  final int? count;

  final Widget filters;
  final Widget content;

  const CommonDeviceSection({
    super.key,
    this.title,
    this.count,
    required this.filters,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title
          Text(
            "$title ($count)",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          ///Filters
          filters,

          const SizedBox(height: 24),

          /// Grid & List
          content,
        ],
      ),
    );
  }
}