import 'package:flutter/material.dart';
import 'package:fusion_app/features/zones/widgets/gain_control.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ZoneHeader extends StatelessWidget {
  final String title;
  final Color color;
  final bool expanded;
  final Function onTap;
  const ZoneHeader({super.key,
    required this.title,
    required this.color,
    this.expanded = false,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        // borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => onTap(),
            child: Container(
              child: Icon(
                expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: context.colorScheme.iconDefault,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.b3SemiBold.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.textPrimary,
              ),
            ),
          ),
          GainControl(),

          const SizedBox(width: 8),
          Icon(Icons.volume_up, color: context.colorScheme.iconWhite),
        ],
      ),
    );
  }
}