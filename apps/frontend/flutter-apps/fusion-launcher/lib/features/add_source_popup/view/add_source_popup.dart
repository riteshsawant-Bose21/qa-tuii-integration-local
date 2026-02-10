import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/parts/properties_and_filter_section.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../view_model/add_source_viewmodel.dart';

class AddSourcePopup extends StatelessWidget {
  final Widget child;
  final void Function()? onSaved;
  final bool isFromBuildingPage;

  const AddSourcePopup({
    super.key,
    required this.child,
    this.onSaved,
    required this.isFromBuildingPage,
  });

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      backgroundColor: const Color(0xFF292826),
      content: BlocProvider<AddSourceViewModel>(
        create: (BuildContext context) {
          return AddSourceViewModel()..init(
            fromBuildingPage: isFromBuildingPage,
            onSaved: onSaved,
          );
        },
        child: Container(
          width: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF292826),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_dialog"),
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ADD SOURCE
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: 'ADD SOURCE',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "close_add_source_popup_button"),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: Navigator.of(context).pop,
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(LucideIcons.x200, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 0.5, height: 0),
              Flexible(
                child: BlocBuilder<AddSourceViewModel, AddSourceViewModelState>(
                  builder: (BuildContext context, AddSourceViewModelState state) {
                    final AddSourceViewModel addSourceViewModel = context.read<AddSourceViewModel>();
                    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

                    final List<ListeningArea> listeningAreas = projectViewModel.getAllListeningAreas();

                    return SingleChildScrollView(
                      padding: const EdgeInsetsGeometry.all(16),
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // FusionRadio<SourceSelectionOption>(
                          //   selected: state.selectedSourceOption,
                          //   options: SourceSelectionOption.values,
                          //   labelBuilder: (SourceSelectionOption option) {
                          //     return FusionAppText(
                          //       text: option.displayName,
                          //       style: context.textTheme.bodyMedium?.copyWith(
                          //         color: context.colorScheme.onSurface,
                          //         fontWeight: FontWeight.w400,
                          //       ),
                          //     );
                          //   },
                          //   onChanged: addSourceViewModel.setSourceOption,
                          // ),
                          // const SizedBox(height: 28),
                          SemanticHelper.container(
                            testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_type"),
                            child: BuildRowPropertyWidget<SourceSectionType>(
                              label: "Type",
                              value: state.selectedSourceSectionType,
                              options: SourceSectionType.values,
                              labelBuilder: (SourceSectionType option) {
                                return FusionAppText(
                                  text: option.displayName,
                                  style: Theme.of(context).textTheme.labelMedium,
                                );
                              },
                              onOptionSelected: (int value, SourceSectionType option) {
                                addSourceViewModel.setSourceSectionType(option);
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: <Widget>[
                              const Expanded(child: SizedBox()),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    ...List<Widget>.generate(state.selectedSources.length, (int index) {
                                      final SourceData? selectedItem = state.selectedSources.elementAtOrNull(index);

                                      return SemanticHelper.container(
                                        testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_item_$index"),
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: BuildingPageDronDown<SourceData>(
                                            value: selectedItem,
                                            hintText: "Select source",
                                            items: state.selectedSourceSectionType.items,
                                            onSelect: (SourceData newValue) {
                                              addSourceViewModel.updateSource(index, newValue);
                                            },
                                            labelBuilder: (SourceData option) {
                                              return SemanticHelper.container(
                                                testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_item_label_$index"),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Row(
                                                    children: <Widget>[
                                                      // image
                                                      Image.asset(
                                                        option.assetPath,
                                                        height: 14,
                                                        width: 14,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: FusionAppText(
                                                          text: option.name,
                                                          style: Theme.of(context).textTheme.labelMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (state.selectedSourceOption == SourceSelectionOption.multipleSources) ...<Widget>[
                            Align(
                              alignment: Alignment.centerRight,
                              child: SemanticHelper.formControl(
                                testId: SemanticHelper.createTestId(SemanticTypes.textInput, "add_source_section_add_button"),
                                child: NeumorphicDarkButton(
                                  onTap: addSourceViewModel.addEmptySource,
                                  backgroundColor: context.colorScheme.surface,
                                  width: 28,
                                  height: 28,
                                  borderRadius: 8,
                                  child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),
                          ],

                          const SizedBox(height: 20),

                          MouseRegion(
                            cursor: isFromBuildingPage ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                            child: IgnorePointer(
                              ignoring: isFromBuildingPage,
                              child: SemanticHelper.container(
                                testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_listening_area_dropdown"),
                                child: BuildRowPropertyWidget<ListeningArea>(
                                  label: "Location",
                                  value: state.selectedListeningArea,
                                  options: listeningAreas,
                                  labelBuilder: (ListeningArea option) {
                                    return FusionAppText(
                                      text: option.name,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                                      ),
                                    );
                                  },
                                  valueBuilder: (ListeningArea option) {
                                    final String? floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: option.id)?.name;

                                    String? zoneName;
                                    zoneName = serviceLocator<ProjectViewModel>().getSubZoneForListeningArea(areaId: option.id)?.name;
                                    zoneName ??= serviceLocator<ProjectViewModel>().getZonesForListeningArea(areaId: option.id)?.name;

                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_listening_area_dropdown_value"),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: FusionAppText(
                                              text: "$floorName / ${option.name}",
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          // floor name/zone name/subszone name
                                          FusionAppText(
                                            text: zoneName ?? 'No zone',
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onOptionSelected: (int value, ListeningArea option) {
                                    addSourceViewModel.setSelectedListeningArea(
                                      option,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          Builder(
                            builder: (BuildContext context) {
                              final (String? zoneName, String? subZoneName) = addSourceViewModel.getZonesForListeningArea;

                              return SemanticHelper.container(
                                testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_zone_info"),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (zoneName != null) ...<Widget>[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: FusionAppText(
                                              text: "",
                                              style: context.textTheme.bodyMedium?.copyWith(
                                                color: context.colorScheme.onSurface,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              height: 32,
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: context.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: FusionAppText(
                                                text: zoneName,
                                                maxLine: 1,
                                                style: Theme.of(context).textTheme.labelMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    if (subZoneName != null) ...<Widget>[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: <Widget>[
                                          const Expanded(child: SizedBox()),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              height: 32,
                                              alignment: Alignment.centerLeft,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              decoration: BoxDecoration(
                                                color: context.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: FusionAppText(
                                                text: subZoneName,
                                                maxLine: 1,
                                                style: Theme.of(context).textTheme.labelMedium,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          const SizedBox(height: 20),

                          MouseRegion(
                            cursor: SystemMouseCursors.forbidden,
                            child: IgnorePointer(
                              child: SemanticHelper.container(
                                testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_signal_type_radio_group"),
                                child: FusionRadio<SignalType>(
                                  selected: SignalType.mono,
                                  options: SignalType.values,
                                  labelBuilder: (SignalType option) {
                                    return FusionAppText(
                                      text: option.displayName,
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        color: context.colorScheme.onSurface,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    );
                                  },
                                  onChanged: (SignalType value) {
                                    addSourceViewModel.setSignalType(value);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          BuildRowPropertyWidget<SourceConnectionType>(
                            label: "Connection",
                            value: state.selectedConnectionType,
                            options: state.selectedSourceSectionType.connectionTypes,
                            labelBuilder: (SourceConnectionType option) {
                              return FusionAppText(
                                text: option.displayName,
                                style: Theme.of(context).textTheme.labelMedium,
                              );
                            },
                            onOptionSelected: (int value, SourceConnectionType option) {
                              addSourceViewModel.setSelectedConnectionType(option);
                            },
                          ),
                          const SizedBox(height: 20),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(
                                child: FusionAppText(
                                  text: "Name",
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_name_input"),
                                  child: TextFormField(
                                    onChanged: (String value) => addSourceViewModel.setSelectedSourceName(value),
                                    maxLength: 24,
                                    decoration: InputDecoration(
                                      hintText: 'Enter name',
                                      counterText: '',
                                      hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                      hoverColor: Colors.transparent,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                      fillColor: context.colorScheme.surface,
                                      isDense: true,
                                    ),
                                    style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              // Cancel & Save buttons
                              GestureDetector(
                                onTap: Navigator.of(context).pop,
                                child: SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "add_source_cancel_button"),
                                  child: FusionAppText(
                                    text: "Cancel",
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      color: context.colorScheme.onSurface,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              SemanticHelper.button(
                                testId: SemanticHelper.createTestId(SemanticTypes.button, "add_source_save_button"),
                                child: NeumorphicDarkButton(
                                  onTap: () {
                                    context.read<AddSourceViewModel>().onSaveTap(context);
                                  },
                                  backgroundColor: context.colorScheme.surface,
                                  text: "Save",
                                  width: 69,
                                  height: 32,
                                  borderRadius: 8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      child: child,
    );
  }
}
