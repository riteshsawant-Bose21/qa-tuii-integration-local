import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/theme/app_theme.dart';
import 'package:fusion_launcher/features/venue_design/presentation/widgets/side_panel/product_query.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import 'package:fusion_lib/fusion_widgets/others/fusion_dockable_panel.dart';

class SIdePanel extends StatelessWidget {
  const SIdePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: <Widget>[
          FusionDockablePanel(
            title: 'ATTRIBUTES',
            child: AttributesSection(),
          ),
          FusionDockablePanel(
            title: 'COST CALCULATOR',
            child: CostCalculatorSection(),
          ),
          FusionDockablePanel(
            title: 'PRODUCT QUERY',
            initiallyExpanded: true,
            child: ProductQuery(),
          ),
        ],
      ),
    );
  }
}

class AttributesSection extends StatelessWidget {
  const AttributesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'SPEAKER ATTRIBUTES',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.greyDark,
              // letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class CostCalculatorSection extends StatelessWidget {
  const CostCalculatorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: 'COST CALCULATOR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: Theme.of(context).colorScheme.greyDark,
              // letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
