part of '../equipment_location_dialog.dart';

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.index,
    required this.product,
    required this.addProduct,
  });

  final int index;
  final EQLProduct product;
  final VoidCallback addProduct;

  @override
  Widget build(BuildContext context) {
    final String? assetImagePath = product.assetPath;
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_dialog_product_tile_$index"),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              spacing: 10,
              children: <Widget>[
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, "equipment_location_dialog_product_tile_image_$index"),
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Builder(
                      builder: (BuildContext context) {
                        if (assetImagePath == null || assetImagePath.isEmpty) {
                          return const SizedBox();
                        }

                        return Image.asset(
                          assetImagePath,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: SemanticHelper.staticText(
                            testId: SemanticHelper.createTestId(SemanticTypes.text, "device_name"),
                            child: FusionAppText(
                              text: product.name,
                              style: context.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          ),
                          const SizedBox(width: 4),
                          // info
                          FusionArrowPopup(
                            content: SizedBox(
                              width: 300,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: product.description, //"L 22.4cm | W 14.7cm | H 8.3cm | 9kg", // TODO: hardcoded
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.onSurface,
                                      ),
                                    ),

                                    // GRID VIEW
                                    Divider(color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
                                    Builder(
                                      builder: (BuildContext context) {
                                        final Map<String, String> details = product.specifications;

                                        final List<Widget> children = <Widget>[
                                          ...details.keys.map((String key) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                FusionAppText(
                                                  text: key,
                                                  style: context.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                                ),
                                                FusionAppText(
                                                  text: details[key]!,
                                                  style: context.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.normal,
                                                    color: context.colorScheme.onSurface.withAlpha(128),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ];

                                        return BuildingPageGridView(children: children);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            child: SemanticHelper.button(
                              testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_dialog_product_tile_info_button_$index"),
                              child: Icon(
                                LucideIcons.info200,
                                size: 12,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SemanticHelper.staticText(
                      testId: SemanticHelper.createTestId(SemanticTypes.text, "cost"),
                      child: FusionAppText(
                        text: "\$${product.price.toStringAsFixed(2)}", // TODO: hardcoded
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
                SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, "equipment_location_dialog_product_tile_add_button_$index"),
                  child: NeumorphicDarkButton(
                    height: 24,
                    width: 24,
                    borderRadius: 6,
                    backgroundColor: null, //isSelected ? FusionDarkColorPallette.green20 : null,
                    child: Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: context.colorScheme.onSurface,
                    ),
                    onTap: () async {
                      addProduct();
                    },
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
