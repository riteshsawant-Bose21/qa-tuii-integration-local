part of '../bill_of_materials_page.dart';

class _PricingPanel extends StatelessWidget {
  const _PricingPanel({required this.totalPrice});
  final double totalPrice;

  @override
  Widget build(BuildContext context) {
    return FusionFlatContainer(
      width: 302,
      semanticsId: 'bom_pricing_panel',
      margin: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FusionAppText(
                semanticId: 'bom_pricing_title',
                text: 'Pricing',
                style: context.textTheme.h5Bold,
              ),
              const Spacer(),
              _actionBtn(context, Icons.file_download_outlined, 'Export', () {}),
              const SizedBox(width: 12),
              _actionBtn(context, Icons.print_outlined, 'Print', () {}),
            ],
          ),
          const SizedBox(height: 24),
          _priceRow(context, 'Total Price', '\$${totalPrice.toStringAsFixed(2)}', bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, String value, {bool bold = false}) {
    final TextStyle style =
        bold
            ? context.textTheme.l1MediumTight.withColor(context.colorScheme.textPrimary)
            : context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        FusionAppText(text: label, semanticId: 'bom_pricing_$label', style: style),
        FusionAppText(text: value, semanticId: 'bom_pricing_${label}_value', style: style),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.elevation4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 13, color: context.colorScheme.textSecondary),
            const SizedBox(width: 4),
            FusionAppText(text: label, semanticId: 'bom_pricing_${label.toLowerCase()}', style: context.textTheme.l1Medium),
          ],
        ),
      ),
    );
  }
}
