import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/add_source_dropdown_list.dart';
import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/add_source_name_textfield.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_switch.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/equip_location.dart';
import 'package:fusion_lib/models/project_entities/mix_scenes.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';
import 'package:fusion_lib/models/project_entities/zone_model.dart';
import '../../../../core/models/products_data.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../configuration_aes67/viewModel/config_aes67_viewmodel.dart';
import '../../view_model/add_source_viewmodel.dart';
import 'add_source_connection.dart';
import '../add_source_popup.dart';
import 'common_widgets/add_sources_dropdown.dart';
import 'aes67_stream_section.dart';
import 'location_dropdown.dart';

class AddSourcesPopupContent extends StatefulWidget {
  final bool isFromBuildingPage;

  const AddSourcesPopupContent({required this.isFromBuildingPage});

  @override
  State<AddSourcesPopupContent> createState() => AddSourcesPopupContentState();
}

class AddSourcesPopupContentState extends State<AddSourcesPopupContent> {
  SourceLocationType? _selectedLocationType = SourceLocationType.zone;

  /// Tracks the selected equipment location locally.
  EquipLocation? _selectedEquipLocation;
  Zone? _selectedZone;
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigAes67Viewmodel, ConfigAes67State>(
      builder: (BuildContext context, ConfigAes67State configState) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState projectState) {
            return BlocBuilder<AddSourceViewModel, AddSourceViewModelState>(
              builder: (BuildContext context, AddSourceViewModelState state) {
                final AddSourceViewModel addSourceViewModel = context.read<AddSourceViewModel>();
                final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // ── Source Name ──────────────────────────
                      SourceNameTextfield(addSourceViewModel: addSourceViewModel),
                      const SizedBox(height: 20),
                      // ── Source Type ──────────────────────────
                      SemanticHelper.dropdown(
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.dropdown,
                          'add_source_section_type',
                        ),
                        child: FusionOutlinedDropdown<SourceSectionType>(
                          label: 'Source Type',
                          hint: 'Select Source Type',
                          borderRadius: 12,
                          value: state.selectedSourceSectionType,
                          items: SourceSectionType.values,
                          itemLabelBuilder: (SourceSectionType item) => item.displayName,
                          onChanged: (SourceSectionType value) => addSourceViewModel.setSourceSectionType(value),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Source items (multi-source dropdowns) ─
                      SourceDropdownList(
                        selectedSources: state.selectedSources,
                        items: state.selectedSourceSectionType.items,
                        onChanged: (int index, SourceData value) {
                          addSourceViewModel.updateSource(index, value);
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Location ─────────────────────────────
                      SourceLocationSection(
                        selectedLocationType: _selectedLocationType ?? SourceLocationType.zone,
                        onLocationTypeChanged: (SourceLocationType type) {
                          setState(() {
                            _selectedLocationType = type;
                            _selectedEquipLocation = null;
                            _selectedZone = null;
                          });
                        },
                        isFromBuildingPage: widget.isFromBuildingPage,
                      ),
                      if (_selectedLocationType == SourceLocationType.zone) ...<Widget>[
                        Builder(
                          builder: (BuildContext context) {
                            final List<Zone> zone = projectViewModel.getAllZones();

                            return FusionOutlinedDropdown<Zone>(
                              hint: 'Select Zone',
                              label: 'Select Zone',
                              value: _selectedZone,
                              items: zone,
                              itemLabelBuilder: (Zone item) => item.name,
                              onChanged: (Zone value) {
                                setState(() => _selectedZone = value);
                                addSourceViewModel.setzone(value.id);
                              },
                            );
                          },
                        ),
                      ],
                      // ── Equipment Location flow ──────────────
                      if (_selectedLocationType == SourceLocationType.equipmentLocation) ...<Widget>[
                        Builder(
                          builder: (BuildContext context) {
                            final List<EquipLocation> equipLocations = projectViewModel.equipLocations;

                            return FusionOutlinedDropdown<EquipLocation>(
                              hint: 'Select Equipment Location',
                              label: 'Select Equipment Location',
                              value: _selectedEquipLocation,
                              items: equipLocations,
                              itemLabelBuilder: (EquipLocation item) => item.name,
                              onChanged: (EquipLocation value) {
                                setState(() => _selectedEquipLocation = value);
                                addSourceViewModel.setSelectedEquipmentLocation(value.id);
                              },
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          FusionSwitch(
                            width: 44,
                            radiusFactor: 0.4,
                            height: 24,
                            value: _selected,
                            onChanged: (bool value) {
                              setState(() => _selected = value);
                              //   TODO -use only in this location yet to be implemented
                            },
                          ),
                          const SizedBox(width: 12),
                          FusionAppText(
                            text: 'Use only in this location',
                            style: context.textTheme.b3Regular.copyWith(
                              color: context.colorScheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ── Signal type & Connection ─────────────
                      SourceConnectionSection(
                        selectedSectionType: state.selectedSourceSectionType,
                        selectedSources: state.selectedSources,

                        selectedSignalType: state.selectedSignalType,
                        signalTypes: addSourceViewModel.signalTypes,
                        onSignalTypeChanged: (SignalType value) {
                          addSourceViewModel.setSignalType(value);
                        },

                        selectedConnectionType: state.selectedConnectionType,
                        onConnectionChanged: (SourceConnectionType value) {
                          addSourceViewModel.setSelectedConnectionType(value);
                        },
                      ),
                      // ── AES67 Stream & Channel assignment ────
                      if (state.selectedConnectionType == SourceConnectionType.aes67input) ...<Widget>[
                        Aes67StreamSection(state: state),
                        const SizedBox(height: 20),
                        ChannelAssignmentSection(state: state),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
