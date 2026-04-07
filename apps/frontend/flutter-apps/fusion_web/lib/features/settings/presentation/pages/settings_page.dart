import 'package:flutter/material.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
                      title: 'Settings',
                      subtitle:
                          'This is a Settings page',
                    ),
        ],
      ),
    );
  }
}
