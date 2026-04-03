import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/models/products_data.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/views/widgets/properties_and_filter_section.dart';
import 'package:fusion_lib/constants/semantics/features/add_sources_popup/add_sources_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configuration_aes67/view/widgets/inputStreams/input_stream_dialog.dart';
import '../../configuration_aes67/viewModel/config_aes67_viewmodel.dart';
import '../../configuration_aes67/viewModel/input_stream_viewmodel/input_stream_viewmodel.dart';
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
      content: BlocProvider<ConfigAes67Viewmodel>(
        create: (_) => ConfigAes67Viewmodel(projectViewModel: serviceLocator<ProjectViewModel>()),
        child: BlocProvider<InputStreamViewmodel>(
          create: (_) => InputStreamViewmodel(projectViewModel: serviceLocator<ProjectViewModel>())..init(),
          child: BlocProvider<AddSourceViewModel>(
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
                      child: BlocBuilder<ConfigAes67Viewmodel, ConfigAes67State>(
                        builder: (BuildContext context, ConfigAes67State configState) {
                          return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                            builder: (BuildContext context, ProjectViewModelState projectState) {
                              return BlocBuilder<AddSourceViewModel, AddSourceViewModelState>(
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
                                                  ...List<Widget>.generate(state.selectedSources.length, (int index) {
                                                    final SourceData? selectedItem = state.selectedSources.elementAtOrNull(index);

                                                    return SemanticHelper.container(
                                                      testId: SemanticHelper.createTestId(
                                                        SemanticTypes.container,
                                                        "${FusionTestKeys.instance.addSourceSectionItem}_$index",
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(bottom: 8.0),
                                                        child: BuildingPageDropDown<SourceData>(
                                                          value: selectedItem,
                                                          hintText: "Select source",
                                                          items: state.selectedSourceSectionType.items,
                                                          onSelect: (SourceData newValue) => addSourceViewModel.updateSource(index, newValue),
                                                          labelBuilder: (SourceData option) {
                                                            return SemanticHelper.container(
                                                              testId: SemanticHelper.createTestId(
                                                                SemanticTypes.container,
                                                                "add_source_section_item_label_$index",
                                                              ),
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
                                                                        maxLine: 1,
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
                                                  final String? floorName =
                                                      serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: option.id)?.name;

                                                  String? zoneName;
                                                  zoneName = serviceLocator<ProjectViewModel>().getSubZoneForListeningArea(areaId: option.id)?.name;
                                                  zoneName ??= serviceLocator<ProjectViewModel>().getZonesForListeningArea(areaId: option.id)?.name;

                                                  return SemanticHelper.container(
                                                    testId: SemanticHelper.createTestId(
                                                      SemanticTypes.container,
                                                      "add_source_section_listening_area_dropdown_value",
                                                    ),
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
                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                            decoration: BoxDecoration(
                                                              boxShadow: <BoxShadow>[
                                                                BoxShadow(color: context.colorScheme.shadowDark, offset: const Offset(1.5, 1.5), blurRadius: 7),
                                                                BoxShadow(
                                                                  color: context.colorScheme.shadowLight,
                                                                  offset: const Offset(-1.5, -1.5),
                                                                  blurRadius: 5,
                                                                ),
                                                              ],
                                                              color: context.colorScheme.elevation1,
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
                                                          child: FusionContainer(
                                                            raised: true,
                                                            borderRadius: 8,
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
                                        if ((state.selectedSourceSectionType == SourceSectionType.mediaSources ||
                                                state.selectedSourceSectionType == SourceSectionType.microPhone) &&
                                            state.selectedSources.firstOrNull != null) ...<Widget>[
                                          SemanticHelper.container(
                                            testId: SemanticHelper.createTestId(
                                              SemanticTypes.container,
                                              FusionTestKeys.instance.addSourceSectionSignalTypeRadioGroup,
                                            ),
                                            child: FusionRadio<SignalType>(
                                              selected: state.selectedSignalType,
                                              options: addSourceViewModel.signalTypes,
                                              labelBuilder: (SignalType option) {
                                                return FusionAppText(
                                                  text: option.displayName,
                                                  style: context.textTheme.l1Regular,
                                                );
                                              },
                                              onChanged: (SignalType value) => addSourceViewModel.setSignalType(value),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          BuildRowPropertyWidget<SourceConnectionType>(
                                            label: "Connection",
                                            value: state.selectedConnectionType,
                                            options: state.selectedSources.firstOrNull?.supportedConnectionTypes ?? <SourceConnectionType>[],
                                            labelBuilder: (SourceConnectionType option) => option.displayName,
                                            onOptionSelected: (int value, SourceConnectionType option) {
                                              addSourceViewModel.setSelectedConnectionType(option);
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        const SizedBox(height: 16),

                                        if (state.selectedConnectionType == SourceConnectionType.aes67input) ...<Widget>[
                                          BlocBuilder<AddSourceViewModel, AddSourceViewModelState>(
                                            builder: (BuildContext context, AddSourceViewModelState state) {
                                              final List<Aes67Config> streams = context.read<ProjectViewModel>().getAllAes67InputStreams();

                                              final List<dynamic> options = <dynamic>[
                                                ...streams,
                                                const AddStreamAction(),
                                              ];

                                              return Row(
                                                children: <Widget>[
                                                  FusionAppText(
                                                    text: "Stream",
                                                    style: context.textTheme.l1Regular,
                                                  ),
                                                  const Spacer(),
                                                  FusionPopupMenu<dynamic>(
                                                    items: <dynamic>[...streams, const AddStreamAction()],
                                                    tooltip: 'Stream',
                                                    semanticsId: 'stream_popup_menu',
                                                    popupOffset: const Offset(0, 2),
                                                    itemPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                    matchChildWidth: false,
                                                    popupwidth: 120,
                                                    onSelected: (dynamic option) {
                                                      if (option is AddStreamAction) {
                                                        InputStreamDialog.show(
                                                          context,
                                                          onSave: (Aes67Config stream) {
                                                            context.read<ProjectViewModel>().addAes67InputStream(stream: stream);
                                                            final List<Aes67Config> updatedStreams = context.read<ProjectViewModel>().getAllAes67InputStreams();
                                                            final Aes67Config matchedStream = updatedStreams.firstWhere(
                                                              (Aes67Config s) => s.id == stream.id,
                                                              orElse: () => stream,
                                                            );
                                                            context.read<AddSourceViewModel>().setSelectedStream(matchedStream);
                                                            context.read<InputStreamViewmodel>().init(existingStream: matchedStream);
                                                          },
                                                        );
                                                        return;
                                                      }

                                                      context.read<AddSourceViewModel>().setSelectedStream(option as Aes67Config);
                                                      context.read<InputStreamViewmodel>().init(existingStream: option);
                                                    },
                                                    itemBuilder: (BuildContext context, dynamic option) {
                                                      if (option is AddStreamAction) {
                                                        return Column(
                                                          children: <Widget>[
                                                            Divider(height: 1, color: context.colorScheme.strokeLight),
                                                            const SizedBox(height: 4),
                                                            SizedBox(
                                                              width: double.infinity,
                                                              child: FusionPrimaryButton(
                                                                label: "ADD STREAM",
                                                                accessLabel: 'add_stream_button',
                                                                height: 28,
                                                                onTap: () {},
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }

                                                      return Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: FusionAppText(
                                                              text: (option as Aes67Config).name,
                                                              maxLine: 1,
                                                              style: context.textTheme.l1Regular.copyWith(
                                                                color:
                                                                    option == state.selectedStream
                                                                        ? context.colorScheme.primary
                                                                        : context.colorScheme.textPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                          if (option == state.selectedStream)
                                                            Icon(
                                                              Icons.check,
                                                              size: 14,
                                                              color: context.colorScheme.primary,
                                                            ),
                                                        ],
                                                      );
                                                    },
                                                    child: Container(
                                                      width: 150,
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: context.colorScheme.elevation1,
                                                        borderRadius: BorderRadius.circular(8),
                                                        boxShadow: <BoxShadow>[
                                                          BoxShadow(
                                                            color: context.colorScheme.shadowLight,
                                                            blurRadius: 2,
                                                            offset: const Offset(-2, -2),
                                                          ),
                                                          BoxShadow(
                                                            color: context.colorScheme.shadowDark,
                                                            blurRadius: 4,
                                                            offset: const Offset(2, 2),
                                                          ),
                                                          BoxShadow(color: context.colorScheme.elevation1),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: FusionAppText(
                                                              maxLine: 1,
                                                              text: state.selectedStream?.name ?? "Select",
                                                              style: context.textTheme.l1Regular.copyWith(
                                                                color:
                                                                    state.selectedStream?.name != null
                                                                        ? context.colorScheme.textPrimary
                                                                        : context.colorScheme.textPlaceholder,
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(
                                                            LucideIcons.chevronDown200,
                                                            color: context.colorScheme.textPrimary,
                                                            size: 16,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),

                                          const SizedBox(height: 16),

                                          // Session (Assigned To) dropdown
                                          // Session dropdown
                                          // BlocBuilder<InputStreamViewmodel, InputStreamState>(
                                          //   builder: (BuildContext context, InputStreamState inputState) {
                                          //     if (inputState is! InputStreamLoaded) {
                                          //       return const SizedBox.shrink();
                                          //     }
                                          //
                                          //     final List<String> sessionOptions = inputState.danteAssignableOptions;
                                          //
                                          //     return BuildRowPropertyWidget<String>(
                                          //       label: "Session",
                                          //       hint: inputState.isLoadingSessions ? 'Loading...' : 'Select session',
                                          //       value: inputState.assignedTo,
                                          //       options: sessionOptions,
                                          //       labelBuilder: (String option) => option,
                                          //       onOptionSelected: (int index, String value) {
                                          //         context.read<InputStreamViewmodel>().updateAssignedTo(value);
                                          //       },
                                          //     );
                                          //   },
                                          // ),
                                          // const SizedBox(height: 16),

                                          // Channel assignment based on signal type
                                          BlocBuilder<InputStreamViewmodel, InputStreamState>(
                                            builder: (BuildContext context, InputStreamState inputState) {
                                              final Aes67Config? selectedStream = state.selectedStream;
                                              final Aes67SessionEntry? selectedSession =
                                                  selectedStream?.sessions
                                                      .where((Aes67SessionEntry s) => s.sessionId == selectedStream.selectedSessionId)
                                                      .firstOrNull;
                                              final List<String> channelOptions =
                                                  inputState is InputStreamLoaded ? inputState.selectedSessionChannelOptions : <String>[];

                                              // Helper to convert stored int channel number back to label
                                              String? channelLabel(int? channelNumber) {
                                                if (channelNumber == null || channelNumber < 1 || channelNumber > channelOptions.length) return null;
                                                return channelOptions[channelNumber - 1];
                                              }

                                              return Column(
                                                children: <Widget>[
                                                  if (state.selectedSignalType == SignalType.mono) ...<Widget>[
                                                    BuildRowPropertyWidget<String>(
                                                      label: "Channel 1",
                                                      hint: "Assign",
                                                      value: channelLabel(state.selectedMonoChannel),
                                                      options: channelOptions,
                                                      labelBuilder: (String option) => option,
                                                      onOptionSelected: (int index, String value) {
                                                        addSourceViewModel.setSelectedMonoChannel(index + 1);
                                                      },
                                                    ),
                                                  ],
                                                  if (state.selectedSignalType == SignalType.stereo) ...<Widget>[
                                                    BuildRowPropertyWidget<String>(
                                                      label: "Channel 1 (Left)",
                                                      hint: "Assign",
                                                      value: channelLabel(state.selectedLeftChannel),
                                                      options: channelOptions,
                                                      labelBuilder: (String option) => option,
                                                      onOptionSelected: (int index, String value) {
                                                        addSourceViewModel.setSelectedLeftChannel(index + 1);
                                                      },
                                                    ),
                                                    const SizedBox(height: 12),
                                                    BuildRowPropertyWidget<String>(
                                                      label: "Channel 2 (Right)",
                                                      hint: "Assign",
                                                      value: channelLabel(state.selectedRightChannel),
                                                      options: channelOptions,
                                                      labelBuilder: (String option) => option,
                                                      onOptionSelected: (int index, String value) {
                                                        addSourceViewModel.setSelectedRightChannel(index + 1);
                                                      },
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 40),
                                        ],
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
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class AddStreamAction {
  const AddStreamAction();
}

class _ChannelDropdown extends StatelessWidget {
  final int? value;
  final List<String> channelOptions;
  final ValueChanged<int?> onChanged;

  const _ChannelDropdown({
    required this.value,
    required this.channelOptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<int, String>> entries =
        channelOptions.asMap().entries.map((MapEntry<int, String> e) => MapEntry<int, String>(e.key + 1, e.value)).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: (value != null && entries.any((MapEntry<int, String> e) => e.key == value)) ? value : null,
          hint: FusionAppText(
            text: 'Assign',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.textSecondary,
            ),
          ),
          isDense: true,
          isExpanded: true,
          dropdownColor: context.colorScheme.elevation2,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.colorScheme.textSecondary),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.textPrimary,
          ),
          items:
              entries
                  .map(
                    (MapEntry<int, String> e) => DropdownMenuItem<int>(
                      value: e.key,
                      child: FusionAppText(
                        text: e.value.isNotEmpty ? e.value : 'Channel ${e.key}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
