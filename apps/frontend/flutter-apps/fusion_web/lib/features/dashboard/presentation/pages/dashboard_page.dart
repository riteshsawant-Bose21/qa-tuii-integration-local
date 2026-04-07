import 'package:flutter/material.dart';
import 'package:fusion_web/features/common-widgets/page_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
                    title: 'Dashboard',
                    subtitle:
                        'This is the main Dashboard page. Welcome to the application!',
                  ),
        ],
      ),
    );
  }
}
