import 'package:flutter/widgets.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final Color fcolor = const Color(0xFF28C772);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE4F7EB).withValues(alpha: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: fcolor,
              shape: BoxShape.circle,
            ),
          ),
          Text("On Track", style: context.textTheme.bodySmall?.copyWith(color: fcolor)),
        ],
      ),
    );
  }
}
