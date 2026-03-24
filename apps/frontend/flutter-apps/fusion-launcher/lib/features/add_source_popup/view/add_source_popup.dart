import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/parts/properties_and_filter_section.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_lib/constants/semantics/features/add_sources_popup/add_sources_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';
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
      semanticId: FusionTestKeys.instance.addSourcesPopup,
      backgroundColor: context.colorScheme.elevation2,
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: SemanticHelper.container(
            testId: SemanticHelper.createTestId(
              SemanticTypes.container,
              FusionTestKeys.instance.addSourcesDialog,
            ),
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
                          style: context.textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.primaryWhite,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SemanticHelper.button(
                        testId: SemanticHelper.createTestId(
                          SemanticTypes.button,
                          FusionTestKeys.instance.closeAddSourcePanel,
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: Navigator.of(context).pop,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: FusionIcon.icon(
                                LucideIcons.x200,
                                size: 10,
                                color: context.colorScheme.iconDefault,
                              ),
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
                    builder: (
                      BuildContext context,
                      AddSourceViewModelState state,
                    ) {
                      final AddSourceViewModel addSourceViewModel = context.read<AddSourceViewModel>();
                      final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

                      final List<ListeningArea> listeningAreas = projectViewModel.getAllListeningAreas();

                      return SingleChildScrollView(
                        padding: const EdgeInsetsGeometry.all(16),
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Expanded(
                                  child: FusionAppText(
                                    text: "Name",
                                    style: context.textTheme.b3Regular.copyWith(
                                      color: context.colorScheme.onSurface,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SemanticHelper.container(
                                    testId: SemanticHelper.createTestId(
                                      SemanticTypes.container,
                                      FusionTestKeys.instance.addSourceNameInput,
                                    ),
                                    child: FusionCustomTextField(
                                      height: 30,
                                      borderRadius: 8,
                                      variant: FusionFieldVariant.neumorphic,
                                      semanticId: '',
                                      hint: 'Enter name',
                                      charlimit: 24,
                                      onChange: (String value) {
                                        addSourceViewModel.setSelectedSourceName(value);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SemanticHelper.dropdown(
                              testId: SemanticHelper.createTestId(SemanticTypes.dropdown, "add_source_section_type"),
                              child: BuildRowPropertyWidget<SourceSectionType>(
                                label: "Type",
                                value: state.selectedSourceSectionType,
                                options: SourceSectionType.values,
                                labelBuilder: (SourceSectionType option) => option.displayName,
                                onOptionSelected: (
                                  int value,
                                  SourceSectionType option,
                                ) {
                                  addSourceViewModel.setSourceSectionType(
                                    option,
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: <Widget>[
                                const Expanded(child: SizedBox()),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      ...List<Widget>.generate(state.selectedSources.length, (
                                        int index,
                                      ) {
                                        final SourceData? selectedItem = state.selectedSources.elementAtOrNull(index);

                                        return SemanticHelper.container(
                                          testId: SemanticHelper.createTestId(
                                            SemanticTypes.container,
                                            "${FusionTestKeys.instance.addSourceSectionItem}_$index",
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: BuildingPageDropDown<SourceData>(
                                              value: selectedItem,
                                              hintText: "Select source",
                                              items: state.selectedSourceSectionType.items,
                                              onSelect: (SourceData newValue) => addSourceViewModel.updateSource(index, newValue),
                                              labelBuilder: (SourceData option) {
                                                return SemanticHelper.container(
                                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "add_source_section_item_label_$index"),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                    child: Row(
                                                      children: <Widget>[
                                                        // image
                                                        Image.asset(
                                                          option.assetPath,
                                                          height: 14,
                                                          width: 14,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Flexible(
                                                          child: FusionAppText(
                                                            maxLine: 1,
                                                            text: option.name,
                                                            style:
                                                                Theme.of(
                                                                  context,
                                                                ).textTheme.labelMedium,
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
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.textInput,
                                    FusionTestKeys.instance.addSourceSectionAddButton,
                                  ),
                                  child: NeumorphicDarkButton(
                                    onTap: addSourceViewModel.addEmptySource,
                                    backgroundColor: context.colorScheme.surface,
                                    width: 28,
                                    height: 28,
                                    borderRadius: 8,
                                    child: Icon(
                                      LucideIcons.plus200,
                                      size: 16,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            MouseRegion(
                              cursor: isFromBuildingPage ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                              child: IgnorePointer(
                                ignoring: isFromBuildingPage,
                                child: SemanticHelper.dropdown(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.dropdown,
                                    FusionTestKeys.instance.addSourceSectionListeningAreaDropdown,
                                  ),
                                  value: state.selectedListeningArea?.name ?? '',
                                  child: BuildRowPropertyWidget<ListeningArea>(
                                    label: "Location",
                                    value: state.selectedListeningArea,
                                    options: listeningAreas,
                                    labelBuilder: (ListeningArea option) => option.name,
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
                                                maxLine: 1,
                                                style: Theme.of(context).textTheme.labelMedium,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            // floor name/zone name/subszone name
                                            FusionAppText(
                                              text: zoneName ?? 'No zone',
                                              maxLine: 1,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onOptionSelected: (int value, ListeningArea option) {
                                      addSourceViewModel.setSelectedListeningArea(option);
                                    },
                                  ),
                                ),
                              ),
                            ),

                            Builder(
                              builder: (BuildContext context) {
                                final (String? zoneName, String? subZoneName) = addSourceViewModel.getZonesForListeningArea;

                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.container,
                                    FusionTestKeys.instance.addSourceSectionZoneInfo,
                                  ),
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
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  boxShadow: <BoxShadow>[
                                                    BoxShadow(color: context.colorScheme.shadowDark, offset: const Offset(1.5, 1.5), blurRadius: 7),
                                                    BoxShadow(color: context.colorScheme.shadowLight, offset: const Offset(-1.5, -1.5), blurRadius: 5),
                                                  ],
                                                  color: context.colorScheme.elevation1,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: FusionAppText(
                                                  text: zoneName,
                                                  maxLine: 1,
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.labelMedium,
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
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: context.colorScheme.surface,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: FusionAppText(
                                                  text: subZoneName,
                                                  maxLine: 1,
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.labelMedium,
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

                            const SizedBox(height: 16),

                            MouseRegion(
                              cursor: SystemMouseCursors.forbidden,
                              child: IgnorePointer(
                                child: SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.container,
                                    FusionTestKeys.instance.addSourceSectionSignalTypeRadioGroup,
                                  ),
                                  child: FusionRadio<SignalType>(
                                    selected: SignalType.mono,
                                    options: SignalType.values,
                                    labelBuilder: (SignalType option) {
                                      return FusionAppText(text: option.displayName, style: context.textTheme.b3Regular);
                                    },
                                    onChanged: (SignalType value) {
                                      addSourceViewModel.setSignalType(value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            BuildRowPropertyWidget<SourceConnectionType>(
                              label: "Connection",
                              value: state.selectedConnectionType,
                              options: state.selectedSourceSectionType.connectionTypes,
                              labelBuilder: (SourceConnectionType option) => option.displayName,
                              onOptionSelected: (
                                int value,
                                SourceConnectionType option,
                              ) {
                                addSourceViewModel.setSelectedConnectionType(
                                  option,
                                );
                              },
                            ),
                            // const SizedBox(height: 16),
                            //
                            // BuildRowPropertyWidget<SourceConnectionType>(
                            //   label: "Stream",
                            //   value: state.selectedConnectionType,
                            //   options: state.selectedSourceSectionType.connectionTypes,
                            //   labelBuilder: (SourceConnectionType option) => option.displayName,
                            //   onOptionSelected: (
                            //     int value,
                            //     SourceConnectionType option,
                            //   ) {
                            //     addSourceViewModel.setSelectedConnectionType(
                            //       option,
                            //     );
                            //   },
                            // ),
                            // const SizedBox(height: 16),
                            //
                            // BuildRowPropertyWidget<SourceConnectionType>(
                            //   label: "Channel",
                            //   value: state.selectedConnectionType,
                            //   options: state.selectedSourceSectionType.connectionTypes,
                            //   labelBuilder: (SourceConnectionType option) => option.displayName,
                            //   onOptionSelected: (
                            //     int value,
                            //     SourceConnectionType option,
                            //   ) {
                            //     addSourceViewModel.setSelectedConnectionType(
                            //       option,
                            //     );
                            //   },
                            // ),
                            const SizedBox(height: 40),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                // Cancel & Save buttons
                                FusionAppButton(
                                  semanticId: FusionTestKeys.instance.addSourceCancelButton,
                                  onPressed: Navigator.of(context).pop,
                                  style: FusionAppButtonStyle.tertiary,
                                  text: "Cancel",
                                  textstyle: context.textTheme.b3Regular,
                                ),

                                const SizedBox(width: 15),
                                FusionAppButton(
                                  style: FusionAppButtonStyle.neumorphic,
                                  semanticId: FusionTestKeys.instance.addSourceSaveButton,
                                  onPressed: () {
                                    context.read<AddSourceViewModel>().onSaveTap(context);
                                  },
                                  color: context.colorScheme.surface,
                                  text: "Save",
                                  textstyle: context.textTheme.b3Regular,
                                  width: 69,
                                  height: 32,
                                  borderRadius: 8,
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
