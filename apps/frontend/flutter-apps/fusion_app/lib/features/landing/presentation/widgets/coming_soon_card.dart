import 'package:flutter/material.dart';

class ComingSoonCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const ComingSoonCard({super.key,required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1F1F1F)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(color: Color(0xFFB5B5B5))),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: Color(0xFF7A7A7A),
                      fontSize: 16,
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
}

