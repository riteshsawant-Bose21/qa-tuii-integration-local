part of '../bill_of_materials_page.dart';

class _ProductListSection extends StatelessWidget {
  const _ProductListSection({required this.searchController});
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BomViewModel, BomState>(
      builder: (BuildContext context, BomState state) {
        final List<BomItem> items = state.filteredItems;
        return FusionFlatContainer(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  FusionAppText(
                    semanticId: 'bom_product_list_title',
                    text: 'Product List',
                    style: context.textTheme.h4Bold,
                  ),
                  const Spacer(),
                  FusionCustomTextField(
                    width: 240,
                    height: 36,
                    hint: 'Search Devices',
                    variant: FusionFieldVariant.neumorphic,
                    controller: searchController,
                    showPrefixIcon: true,
                    prefixIcon: Icons.search,
                    showLabel: false,

                    semanticId: '',
                  ),
                  const SizedBox(width: 8),
                  _iconBtn(context, Icons.sort),
                  const SizedBox(width: 4),
                  _iconBtn(context, Icons.filter_alt_outlined),
                ],
              ),
              Expanded(
                child:
                    items.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.inventory_2_outlined, size: 48, color: context.colorScheme.textSecondary),
                              const SizedBox(height: 12),
                              FusionAppText(
                                semanticId: 'bom_no_items_text',
                                text: state.searchQuery.isNotEmpty ? 'No results for "${state.searchQuery}"' : 'No devices in this category',
                                style: context.textTheme.l1Regular.withColor(context.colorScheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                        : FusionAppTable(
                          semanticId: 'bom_product_table',
                          spacing: 16,
                          headers: <FusionTableHeader>[
                            FusionTableHeader(title: '', flex: 1, aligment: Alignment.center),
                            FusionTableHeader(
                              title: 'DEVICE NAME',
                              flex: 3,
                            ),
                            FusionTableHeader(
                              title: 'MODEL',
                              flex: 2,
                            ),
                            FusionTableHeader(title: 'UNIT PRICE', flex: 2, aligment: Alignment.center),
                            FusionTableHeader(title: 'QUANTITY', flex: 2, aligment: Alignment.center),
                            FusionTableHeader(title: 'AMOUNT', flex: 2, aligment: Alignment.center),
                            // FusionTableHeader(title: 'AVAILABILITY', flex: 2, aligment: Alignment.center),
                          ],
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, int index) {
                            final BomItem item = items[index];
                            final bool available = item.quantity > 0;
                            return <Widget>[
                              // Thumbnail
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.elevation3,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: FusionImageAuto(
                                    path: item.imageUrl,
                                    fit: BoxFit.contain,
                                    fallbackIcon: Icon(Icons.device_unknown, color: context.colorScheme.textSecondary, size: 20),
                                    errorBuilder: (_, __, ___) => Icon(Icons.device_unknown, color: context.colorScheme.textSecondary, size: 20),
                                  ),
                                ),
                              ),

                              // Device Name + model sub-text
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  FusionAppText(
                                    semanticId: 'bom_item_name_$index',
                                    text: item.name,
                                    maxLine: 1,
                                    style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
                                  ),
                                  FusionAppText(
                                    semanticId: 'bom_item_submodel_$index',
                                    text: item.model,
                                    maxLine: 1,
                                    style: context.textTheme.b3Regular.withColor(context.colorScheme.textSecondary),
                                  ),
                                ],
                              ),

                              // Model
                              FusionAppText(
                                semanticId: 'bom_item_model_$index',
                                text: item.model,
                                maxLine: 1,
                                style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                              ),

                              // Unit Price
                              FusionAppText(
                                semanticId: 'bom_item_price_$index',
                                text: '\$${item.unitPrice.toStringAsFixed(1)}',
                                style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                              ),

                              // Quantity
                              FusionAppText(
                                semanticId: 'bom_item_qty_$index',
                                text: item.quantity.toString().padLeft(2, '0'),
                                style: context.textTheme.l1Regular.withColor(context.colorScheme.textBody),
                              ),

                              // Amount
                              FusionAppText(
                                semanticId: 'bom_item_amount_$index',
                                text: '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                style: context.textTheme.l1MediumTight.withColor(context.colorScheme.textBody),
                              ),

                              // // Availability
                              // Row(
                              //   mainAxisSize: MainAxisSize.min,
                              //   children: <Widget>[
                              //     // container with green or red dot based on availability
                              //     Container(
                              //       width: 16,
                              //       height: 16,
                              //       decoration: BoxDecoration(
                              //         color: available ? context.colorScheme.primary : context.colorScheme.elevation4,
                              //         borderRadius: BorderRadius.circular(4),
                              //       ),
                              //     ),
                              //     const SizedBox(width: 8),
                              //     FusionAppText(
                              //       semanticId: 'bom_item_avail_$index',
                              //       text: available ? 'Available' : 'Out of stock',
                              //       style: context.textTheme.b3Regular.withColor(
                              //         context.colorScheme.textPrimary,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ];
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Icon(icon, size: 18, color: context.colorScheme.textSecondary),
    );
  }
}
