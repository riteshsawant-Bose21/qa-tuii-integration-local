import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/neumorphic_button.dart';

class FunctionItem extends StatelessWidget {
  final String title;
  final String? badge;
  final bool disabled;

  const FunctionItem({super.key, required this.title, this.badge, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return FusionContainer(
      raised: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: disabled ? Colors.black12 : const Color(0xFF1A1A18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: disabled ? Colors.white30 : Colors.white),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge!, style: const TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}