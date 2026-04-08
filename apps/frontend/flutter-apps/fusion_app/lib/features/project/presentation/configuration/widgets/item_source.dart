import 'package:flutter/material.dart';
import 'package:fusion_app/features/project/presentation/configuration/widgets/meter_gradient.dart';

class SourceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool showLink;
  final bool showSettings;
  final List listMeters;

  const SourceRow({super.key,
    required this.icon,
    required this.title,
    this.showLink = false,
    this.listMeters = const ["1"],
    this.showSettings = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
        ...listMeters.map((item)=>Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          child: MeterGradient(
            width: 5,
            height: 20,
            borderRadius: BorderRadius.circular(2),
          ),
        )),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color:  Theme.of(context).colorScheme.onPrimary, fontSize: 16),
            ),
          ),
          if (showLink)
             Icon(Icons.link, color: Theme.of(context).colorScheme.onPrimary),
          if (showSettings) ...[
            const SizedBox(width: 12),
            Icon(Icons.tune, color: Theme.of(context).colorScheme.onPrimary),
          ],
        ],
      ),
    );
  }
}
