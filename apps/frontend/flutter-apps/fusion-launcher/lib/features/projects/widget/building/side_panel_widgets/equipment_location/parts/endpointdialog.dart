import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart';

import '../../../../../../../core/service_locator.dart';
import '../../../../../../add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import '../../../../../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import '../../../../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../../../../create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import '../../../../../../create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';
import '../../../../../../speaker_selection_popup/viewmodel/product_query_view_model.dart';
import '../../../../../models/eql_product.dart';
import '../../../../../viewmodel/eql_products_vm.dart';

// ─── Device category ──────────────────────────────────────────

enum EndpointDeviceCategory { endpoint, processor, amplifier }

extension EndpointDeviceCategoryX on EndpointDeviceCategory {
  String get drawerTitle => switch (this) {
    EndpointDeviceCategory.endpoint => 'Add Endpoint',
    EndpointDeviceCategory.processor => 'Add Fusion Device',
    EndpointDeviceCategory.amplifier => 'Add Amplifier',
  };

  String get buttonLabel => switch (this) {
    EndpointDeviceCategory.endpoint => 'Save Endpoint',
    EndpointDeviceCategory.processor => 'Save Fusion Device',
    EndpointDeviceCategory.amplifier => 'Save Amplifier',
  };

  String get typeLabel => switch (this) {
    EndpointDeviceCategory.endpoint => 'Endpoint Type',
    EndpointDeviceCategory.processor => 'Processor Type',
    EndpointDeviceCategory.amplifier => 'Amplifier Type',
  };

  EQLDeviceType get eqlDeviceType => switch (this) {
    EndpointDeviceCategory.endpoint => EQLDeviceType.endpoint,
    EndpointDeviceCategory.processor => EQLDeviceType.processor,
    EndpointDeviceCategory.amplifier => EQLDeviceType.amplifier,
  };
}

// ─── Enums ────────────────────────────────────────────────────

enum EndpointLocationType {
  zone,
  equipmentLocation;

  String get displayName => switch (this) {
    EndpointLocationType.zone => 'Zone',
    EndpointLocationType.equipmentLocation => 'Equipment Location',
  };
}

enum SourceType {
  mic,
  line,
  instrument;

  String get displayName => switch (this) {
    SourceType.mic => 'Mic',
    SourceType.line => 'Line',
    SourceType.instrument => 'Instrument',
  };
}

// ─── Data model ───────────────────────────────────────────────

class EndpointFormData {
  final String endpointName;
  final EQLProduct product;
  final EndpointLocationType locationType;
  final String locationId;
  final bool addConnectedSource;
  final String? sourceName;
  final SourceType? sourceType;

  const EndpointFormData({
    required this.endpointName,
    required this.product,
    required this.locationType,
    required this.locationId,
    required this.addConnectedSource,
    this.sourceName,
    this.sourceType,
  });
}

// ─── Location item helper ─────────────────────────────────────

class _LocationItem {
  final String id;
  final String name;
  const _LocationItem({required this.id, required this.name});
}

// ─────────────────────────────────────────────────────────────
// Outer StatelessWidget
// ─────────────────────────────────────────────────────────────

// ── 2. _AddEndpointDialogWidget threads it through ────────────

class _AddEndpointDialogWidget extends StatelessWidget {
  const _AddEndpointDialogWidget({
    required this.category,
    required this.saveEnabledNotifier,
    required this.formKey,
    required this.fromBuildingPage, // ← added
    required this.onSave,
  });

  final EndpointDeviceCategory category;
  final ValueNotifier<bool> saveEnabledNotifier;
  final GlobalKey<_EndpointFormState> formKey;
  final bool fromBuildingPage; // ← added
  final void Function(EndpointFormData data)? onSave;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<EqlProductsVm>(
          create:
              (BuildContext context) => EqlProductsVm(
                BlocProvider.of<ProjectViewModel>(context),
                BlocProvider.of<ProductQueryViewModel>(context),
                initialFilter: category.eqlDeviceType,
              ),
        ),
      ],
      child: _EndpointForm(
        key: formKey,
        initialCategory: category,
        saveEnabledNotifier: saveEnabledNotifier,
        fromBuildingPage: fromBuildingPage,
        onSave: onSave,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Inner StatefulWidget — form
// ─────────────────────────────────────────────────────────────

// ── 3. _EndpointForm — category becomes initialCategory ───────

class _EndpointForm extends StatefulWidget {
  const _EndpointForm({
    super.key,
    required this.initialCategory,
    required this.saveEnabledNotifier,
    required this.fromBuildingPage,
    required this.onSave,
  });

  final EndpointDeviceCategory initialCategory;
  final ValueNotifier<bool> saveEnabledNotifier;
  final bool fromBuildingPage;
  final void Function(EndpointFormData data)? onSave;

  @override
  State<_EndpointForm> createState() => _EndpointFormState();
}

class _EndpointFormState extends State<_EndpointForm> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _sourceNameCtrl = TextEditingController();
  final GlobalKey _connectedSourceKey = GlobalKey();

  late EndpointDeviceCategory _category;
  EQLProduct? _selectedProduct;
  EndpointLocationType? _locationType;
  _LocationItem? _selectedLocation;
  bool _addConnectedSource = false;
  bool _wasAddConnectedSource = false;
  SourceType? _sourceType;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    widget.saveEnabledNotifier.value = false;
    _nameCtrl.addListener(_revalidate);
    _sourceNameCtrl.addListener(_revalidate);
  }

  bool get _canSave {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_selectedProduct == null) return false;
    if (_locationType == null) return false;
    if (_selectedLocation == null) return false;
    if (_addConnectedSource) {
      if (_sourceNameCtrl.text.trim().isEmpty) return false;
      if (_sourceType == null) return false;
    }
    return true;
  }

  void _revalidate() {
    widget.saveEnabledNotifier.value = _canSave;
  }

  void save() {
    if (!_canSave || !mounted) return;

    final EqlProductsVm vm = BlocProvider.of<EqlProductsVm>(context);

    if (_locationType == EndpointLocationType.equipmentLocation) {
      vm.addProductToLocation(
        equipLocationId: _selectedLocation!.id,
        product: _selectedProduct!,
      );
    } else {
      // Zone — TODO: wire to ProjectViewModel zone method when available --Anirudha
    }

    widget.onSave?.call(
      EndpointFormData(
        endpointName: _nameCtrl.text.trim(),
        product: _selectedProduct!,
        locationType: _locationType!,
        locationId: _selectedLocation!.id,
        addConnectedSource: _addConnectedSource,
        sourceName: _addConnectedSource ? _sourceNameCtrl.text.trim() : null,
        sourceType: _addConnectedSource ? _sourceType : null,
      ),
    );

    Navigator.of(context).maybePop();
  }

  void _scrollToConnectedSource() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? ctx = _connectedSourceKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.9,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sourceNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_addConnectedSource && !_wasAddConnectedSource) {
      _scrollToConnectedSource();
    }
    _wasAddConnectedSource = _addConnectedSource;

    final ProjectViewModel pvm = BlocProvider.of<ProjectViewModel>(context);

    final List<_LocationItem> zones = pvm.zones.map((Zone z) => _LocationItem(id: z.id, name: z.name)).toList();

    final List<_LocationItem> equipmentLocations = pvm.equipLocations.map((EquipLocation e) => _LocationItem(id: e.id, name: e.name)).toList();

    final List<_LocationItem> currentLocations = _locationType == EndpointLocationType.zone ? zones : equipmentLocations;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ── Endpoint Name ──────────────────────────────────
          FusionLabeledField(
            label: 'Endpoint Name',
            semanticId: 'endpoint_name_label',
            child: FusionBorderedTextField(
              controller: _nameCtrl,
              semanticId: 'endpoint_name_field',
              hintText: 'Enter endpoint name',
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          // ── Category chip selector (building page only) ────
          if (widget.fromBuildingPage) ...<Widget>[
            const SizedBox(height: 20),

            FusionOutlinedDropdown<EndpointDeviceCategory>(
              label: 'Device Type',
              hint: 'Select Device Type',
              value: _category,
              items: EndpointDeviceCategory.values,
              itemLabelBuilder:
                  (EndpointDeviceCategory c) => switch (c) {
                    EndpointDeviceCategory.endpoint => 'Endpoint',
                    EndpointDeviceCategory.processor => 'Processor',
                    EndpointDeviceCategory.amplifier => 'Amplifier',
                  },
              onChanged: (EndpointDeviceCategory v) {
                setState(() {
                  _category = v;
                  _selectedProduct = null;
                  BlocProvider.of<EqlProductsVm>(context).updateFilters(
                    BlocProvider.of<EqlProductsVm>(context).state.filters.copyWith(
                      deviceType: v.eqlDeviceType,
                    ),
                  );
                });
                _revalidate();
              },
            ),
            const SizedBox(height: 20),
          ],

          // ── Type — from EqlProductsVm ──────────────────────
          BlocBuilder<EqlProductsVm, EQLProductsState>(
            builder: (BuildContext context, EQLProductsState state) {
              return switch (state.data) {
                EQLProductsLoading() => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CupertinoActivityIndicator(),
                  ),
                ),
                EQLProductsError(:final String message) => FusionAppText(
                  text: 'Error loading types: $message',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colorScheme.error),
                ),
                EQLProductsLoaded(:final List<EQLProduct> products) => FusionOutlinedDropdown<EQLProduct>(
                  label: _category.typeLabel,
                  hint: 'Select ${_category.typeLabel}',
                  value: _selectedProduct,
                  items: products,
                  itemLabelBuilder: (EQLProduct p) => p.name,
                  selectedItemBuilder:
                      (BuildContext ctx, EQLProduct p) => Row(
                        children: <Widget>[
                          Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FusionImageAuto(
                              path: serviceLocator<ProductQueryViewModel>().getProductImage(p.productId),
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FusionAppText(
                              text: p.name,
                              maxLine: 1,
                              style: ctx.textTheme.b3Regular.copyWith(
                                color: ctx.colorScheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  itemWidgetBuilder:
                      (BuildContext ctx, EQLProduct p, bool isSelected) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 28,
                              height: 28,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FusionImageAuto(
                                path: serviceLocator<ProductQueryViewModel>().getProductImage(p.productId),
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FusionAppText(
                                text: p.name,
                                maxLine: 1,
                                style: ctx.textTheme.b3Regular.copyWith(
                                  color: ctx.colorScheme.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              FusionIcon.icon(
                                Icons.check,
                                size: 14,
                                color: ctx.colorScheme.iconWhite,
                              ),
                          ],
                        ),
                      ),
                  onChanged: (EQLProduct v) {
                    setState(() => _selectedProduct = v);
                    _revalidate();
                  },
                ),
                _ => const SizedBox.shrink(),
              };
            },
          ),
          const SizedBox(height: 20),

          // ── Location ──────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FusionAppText(
                text: 'Location',
                style: context.textTheme.l1Medium.copyWith(
                  color: context.colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              FusionRadioChipSelector<EndpointLocationType>(
                selected: _locationType,
                options: EndpointLocationType.values,
                labelBuilder: (EndpointLocationType t) => t.displayName,
                onChanged: (EndpointLocationType v) {
                  setState(() {
                    _locationType = v;
                    _selectedLocation = null;
                  });
                  _revalidate();
                },
              ),
            ],
          ),

          // ── Select Zone / Equipment Location ──────────────
          if (_locationType != null) ...<Widget>[
            const SizedBox(height: 20),
            FusionOutlinedDropdown<_LocationItem>(
              label: _locationType == EndpointLocationType.zone ? 'Select Zone' : 'Select Equipment Location',
              hint: _locationType == EndpointLocationType.zone ? 'Select zone' : 'Select equipment location',
              value: _selectedLocation,
              items: currentLocations,
              itemLabelBuilder: (_LocationItem l) => l.name,
              onChanged: (_LocationItem v) {
                setState(() => _selectedLocation = v);
                _revalidate();
              },
            ),
          ],
          // ── Add connected source toggle ────────────────────
          if (_locationType != null) ...<Widget>[
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                FusionSwitch(
                  value: _addConnectedSource,
                  onChanged: (bool v) {
                    setState(() => _addConnectedSource = v);
                    _revalidate();
                  },
                  width: 44,
                  height: 24,
                ),
                const SizedBox(width: 12),
                FusionAppText(
                  text: 'Add connected source',
                  style: Theme.of(context).textTheme.l1Regular,
                ),
              ],
            ),
          ],

          // ── Connected source fields ────────────────────────
          if (_addConnectedSource) ...<Widget>[
            const SizedBox(height: 20),
            SizedBox(
              key: _connectedSourceKey,
              child: FusionLabeledField(
                label: 'Source Name',
                semanticId: 'source_name_label',
                child: FusionBorderedTextField(
                  controller: _sourceNameCtrl,
                  semanticId: 'source_name_field',
                  hintText: 'Enter source name',
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FusionOutlinedDropdown<SourceType>(
              label: 'Source Type',
              hint: 'Select Source Type',
              value: _sourceType,
              items: SourceType.values,
              itemLabelBuilder: (SourceType t) => t.displayName,
              onChanged: (SourceType v) {
                setState(() => _sourceType = v);
                _revalidate();
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Public API ───────────────────────────────────────────────

class AddEndpointDialog {
  AddEndpointDialog._();

  // ── 1. show() gets fromBuildingPage param ─────────────────────

  static Future<void> show({
    required BuildContext context,
    required EndpointDeviceCategory category,
    bool fromBuildingPage = false, // ← added
    void Function(EndpointFormData data)? onSave,
  }) {
    final ValueNotifier<bool> saveEnabled = ValueNotifier<bool>(false);
    final GlobalKey<_EndpointFormState> formKey = GlobalKey<_EndpointFormState>();

    return FusionDrawer.show<void>(
      context: context,
      semanticId: 'add_endpoint_${category.name}',
      title: category.drawerTitle,
      buttonLabel: category.buttonLabel,
      buttonEnabledNotifier: saveEnabled,
      onButtonPressed: () => formKey.currentState?.save(),
      content: _AddEndpointDialogWidget(
        category: category,
        saveEnabledNotifier: saveEnabled,
        formKey: formKey,
        fromBuildingPage: fromBuildingPage,
        onSave: onSave,
      ),
    );
  }
}
