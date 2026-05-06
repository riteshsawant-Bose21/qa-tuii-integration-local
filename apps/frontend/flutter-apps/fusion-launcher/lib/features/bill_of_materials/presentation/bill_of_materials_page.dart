import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/widgets/fusion_app_table.dart';
import 'package:fusion_launcher/features/bill_of_materials/state/bom_state.dart';
import 'package:fusion_launcher/features/bill_of_materials/viewmodel/bom_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';

import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

part 'widgets/bom_sidebar.dart';
part 'sections/product_list_section.dart';
part 'sections/hardware_requirements_section.dart';
part 'sections/pricing_panel_section.dart';

class BillOfMaterialsPage extends StatelessWidget {
  const BillOfMaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BomViewModel>(
      create: (_) => BomViewModel(),
      child: const _BillOfMaterialsView(),
    );
  }
}

class _BillOfMaterialsView extends StatefulWidget {
  const _BillOfMaterialsView();

  @override
  State<_BillOfMaterialsView> createState() => _BillOfMaterialsViewState();
}

class _BillOfMaterialsViewState extends State<_BillOfMaterialsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<BomViewModel>().search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BomViewModel, BomState>(
      /// Reload when the outer ProjectViewModel changes (e.g. new device added)
      listener: (BuildContext context, BomState state) {},
      builder: (BuildContext context, BomState state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primaryBlack,
          body: BlocListener<ProjectViewModel, ProjectViewModelState>(
            listener: (BuildContext context, ProjectViewModelState projectState) {
              context.read<BomViewModel>().refresh();
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BomSidebar(
                  selected: state.selectedCategory,
                  onSelected: (BomCategory cat) => context.read<BomViewModel>().changeCategory(cat),
                ),
                Expanded(
                  child:
                      state.selectedCategory == BomCategory.hardwareRequirements
                          ? const _HardwareRequirementsSection()
                          : _ProductListSection(searchController: _searchController),
                ),
                _PricingPanel(
                  totalPrice: state.totalPrice,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
