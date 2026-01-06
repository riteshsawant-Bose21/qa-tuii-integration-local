import 'package:equatable/equatable.dart';
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

class AddSourceViewModelState extends Equatable {
  final SourceOption selectedSourceOption;
  final List<SourceData> selectedSources;
  // Selected listening area IDs per source row (index aligned with selectedSources)
  final String? selectedListeningAreaId;

  // Just for UI
  final int totalSourceTypeCount; // initialliy 1

  const AddSourceViewModelState({
    this.selectedSourceOption = SourceOption.singleSource,
    this.selectedSources = const <SourceData>[],
    this.selectedListeningAreaId,
    this.totalSourceTypeCount = 1,
  });

  AddSourceViewModelState copyWith({
    SourceOption? selectedSourceOption,
    List<SourceData>? selectedSources,
    String? selectedListeningAreaId,
    int? totalSourceTypeCount,
  }) {
    return AddSourceViewModelState(
      selectedSourceOption: selectedSourceOption ?? this.selectedSourceOption,
      selectedSources: selectedSources ?? this.selectedSources,
      selectedListeningAreaId: selectedListeningAreaId ?? this.selectedListeningAreaId,
      totalSourceTypeCount: totalSourceTypeCount ?? this.totalSourceTypeCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[selectedSourceOption, selectedSources, selectedListeningAreaId, totalSourceTypeCount];
}

class AddSourceViewModel extends Cubit<AddSourceViewModelState> {
  AddSourceViewModel() : super(const AddSourceViewModelState());

  void setSourceOption(SourceOption sourceOption) {
    if (sourceOption == state.selectedSourceOption) return;

    final List<SourceData> sources = List<SourceData>.from(state.selectedSources);

    if (sourceOption == SourceOption.singleSource) {
      final List<SourceData> selectedSources = sources.isNotEmpty ? <SourceData>[sources.first] : <SourceData>[];
      emit(
        state.copyWith(selectedSourceOption: sourceOption, selectedSources: selectedSources, totalSourceTypeCount: 1),
      );
    } else {
      emit(state.copyWith(selectedSourceOption: sourceOption, selectedSources: sources));
    }
  }

  void increaseSelectionSourceCount() {
    // Only allow increasing in multiple sources mode
    if (state.selectedSourceOption == SourceOption.multipleSources) {
      emit(state.copyWith(totalSourceTypeCount: state.totalSourceTypeCount + 1));
    }
  }

  void addSource(int index, SourceData source) {
    final List<SourceData> sources = List<SourceData>.from(state.selectedSources);
    if (sources.length <= index) {
      sources.add(source);
    } else {
      sources[index] = source;
    }
    emit(state.copyWith(selectedSources: sources.toList()));
  }

  void removeSource(Source source) {
    final Set<SourceData> sources = Set<SourceData>.from(state.selectedSources);
    sources.remove(source);
    // Trim LA list accordingly

    emit(state.copyWith(selectedSources: sources.toList()));
  }

  void setListeningArea(String? listeningAreaId) {
    emit(state.copyWith(selectedListeningAreaId: listeningAreaId));
  }

  onSaveTap(BuildContext context) {
    // Save: add selected sources to chosen listening areas
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final String? selectedAreaId = state.selectedListeningAreaId;
    if (selectedAreaId == null) return;
    final ListeningArea? selectedArea = projectViewModel.getAllListeningAreas().firstWhereOrNull((ListeningArea la) => la.id == selectedAreaId);
    if (selectedArea == null) return;
    final FloorModel? floorData = projectViewModel.getFloorForListeningArea(areaId: selectedAreaId);
    final String? floorId = floorData?.id;

    for (int i = 0; i < state.selectedSources.length; i++) {
      final SourceData selectedItem = state.selectedSources.first;

      /// Sources [onTapAddDevice]
      final SourceConnectionType connectType = SourceData.getSourceConnectionType(selectedItem.id);
      final PortType portType = switch (connectType) {
        SourceConnectionType.analogInput || SourceConnectionType.aes67input => PortType.analogOutput,
        SourceConnectionType.bluetooth => PortType.bleOut,
        SourceConnectionType.usb => PortType.usbOut,
      };

      final Source source = Source(
        name: selectedItem.name,
        pos: null,
        type: selectedItem.type,
        addedFromBuildingPage: false,
        connectionType: connectType,
        assetImagePath: selectedItem.assetPath,
        locationEntity: LocationModel(
          listeningAreaId: selectedAreaId,
          floorId: floorId,
        ),
        sku: selectedItem.id,
        price: selectedItem.price,
        portData: HardwarePortData(
          inputPorts: 0,
          outputPorts: 1,
          inputPortType: PortType.analogInput,
          outputPortType: portType,
          compatibleInputTypes: <PortType>[],
          compatibleOutputTypes: switch (connectType) {
            SourceConnectionType.analogInput || SourceConnectionType.aes67input => <PortType>[
              PortType.dspAnalogInput,
              PortType.endpointInput,
            ],
            SourceConnectionType.bluetooth => <PortType>[
              PortType.bleIn,
            ],
            SourceConnectionType.usb => <PortType>[PortType.usbIn],
          },
          portPosition: PortPosition.topLeft,
        ),
      );
      serviceLocator<ProjectViewModel>().addHardware(
        hardware: source,
      );
      FusionToast.success(context, message: "Source \"${selectedItem.name}\" added");
    }
  }
}

enum SourceOption {
  singleSource("Single Source"),
  multipleSources("Multiple Sources");

  const SourceOption(this.displayName);
  final String displayName;
}

enum SourceOptionType {
  mono("Mono"),
  stereo("Stereo"),
  monoSum("Mono-Sum");

  const SourceOptionType(this.displayName);
  final String displayName;
}

class AddSourcePopup extends StatelessWidget {
  final Widget child;
  const AddSourcePopup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      blurAmount: 1,
      backgroundColor: const Color(0xFF292826),
      content: const _NewWidget(),
      child: child,
    );
  }
}

class _NewWidget extends StatelessWidget {
  const _NewWidget();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddSourceViewModel>(
      create: (BuildContext context) => AddSourceViewModel(),
      child: Container(
        width: 350,
        decoration: BoxDecoration(
          color: const Color(0xFF292826),
          borderRadius: BorderRadius.circular(16),
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
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(LucideIcons.x200, size: 16),
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
                  final List<Source> sources = projectViewModel.sources;

                  return SingleChildScrollView(
                    padding: const EdgeInsetsGeometry.all(16),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FusionRadio<SourceOption>(
                          selected: state.selectedSourceOption,
                          options: SourceOption.values,
                          labelBuilder: (SourceOption option) {
                            return FusionAppText(
                              text: option.displayName,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                          onChanged: (SourceOption value) {
                            addSourceViewModel.setSourceOption(value);
                          },
                        ),
                        const SizedBox(height: 28),

                        ...List<Widget>.generate(state.totalSourceTypeCount, (int index) {
                          final SourceData? selectedItem = state.selectedSources.elementAtOrNull(index);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: MultiSectionDropDown<SourceData>(
                              value: selectedItem,
                              hintText: "Select type",
                              sections: <DropdownSection<SourceData>>[
                                const DropdownSection<SourceData>(
                                  title: "MICROPHONES",
                                  items: SourceData.microphoneItems,
                                ),

                                const DropdownSection<SourceData>(
                                  title: "MEDIA SOURCES",
                                  items: SourceData.mediaSourceItems,
                                ),
                              ],
                              onSelect: (SourceData selectedItem) {
                                addSourceViewModel.addSource(index, selectedItem);
                              },
                              labelBuilder: (SourceData option) {
                                return Row(
                                  spacing: 5,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Image.asset(
                                      option.assetPath,
                                      height: 14,
                                      width: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: FusionAppText(
                                        text: option.name,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        }),
                        AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: state.selectedSourceOption == SourceOption.multipleSources ? 1 : 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: NeumorphicDarkButton(
                              onTap: addSourceViewModel.increaseSelectionSourceCount,
                              backgroundColor: context.colorScheme.surface,
                              width: 28,
                              height: 28,
                              borderRadius: 8,
                              child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Builder(
                          builder: (BuildContext context) {
                            final List<ListeningArea> allListeningAreas = projectViewModel.getAllListeningAreas();
                            final String? selectedAreaId = state.selectedListeningAreaId;
                            final ListeningArea? selectedArea = allListeningAreas.firstWhereOrNull((ListeningArea la) => la.id == selectedAreaId);

                            if (allListeningAreas.isNotEmpty) {
                              return BuildingPageDronDown<ListeningArea>(
                                value: selectedArea,
                                items: allListeningAreas,
                                labelBuilder: (ListeningArea option) {
                                  return FusionAppText(
                                    text: option.name,
                                    maxLine: 1,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  );
                                },
                                hintText: "Select listening area",
                                onSelect: (ListeningArea newValue) {
                                  addSourceViewModel.setListeningArea(newValue.id);
                                },
                              );
                            } else {
                              return NeumorphicDarkButton(
                                onTap: () async {
                                  // Simple create new listening area dialog
                                  final TextEditingController nameCtrl = TextEditingController();
                                  FloorModel? selectedFloor;
                                  await showDialog<void>(
                                    context: context,
                                    builder: (BuildContext ctx) {
                                      final List<FloorModel> floors = projectViewModel.getAllFloors();
                                      selectedFloor = floors.isNotEmpty ? floors.first : null;
                                      return AlertDialog(
                                        title: const Text("Create Listening Area"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
                                            const SizedBox(height: 8),
                                            DropdownButton<FloorModel>(
                                              value: selectedFloor,
                                              items: floors.map((FloorModel f) => DropdownMenuItem<FloorModel>(value: f, child: Text(f.name))).toList(),
                                              onChanged: (FloorModel? val) => selectedFloor = val,
                                            ),
                                          ],
                                        ),
                                        actions: <Widget>[
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                            },
                                            child: const Text("Create"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if ((nameCtrl.text.trim().isNotEmpty) && selectedFloor != null) {
                                    final ListeningArea newArea = ListeningArea(vertices: const <Offset>[], name: nameCtrl.text.trim());
                                    projectViewModel.addListeningArea(area: newArea, floorId: selectedFloor!.id);
                                    addSourceViewModel.setListeningArea(newArea.id);
                                  }
                                },
                                backgroundColor: context.colorScheme.surface,
                                height: 28,
                                borderRadius: 8,
                                child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 6,
                              children: <Widget>[
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF595752),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                                DefaultTextStyle.merge(
                                  style: context.textTheme.bodySmall,
                                  child: FusionAppText(
                                    text: "Use only in this location",
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        FusionRadio<SourceOptionType>(
                          selected: SourceOptionType.mono,
                          options: SourceOptionType.values,
                          labelBuilder: (SourceOptionType option) {
                            return FusionAppText(
                              text: option.displayName,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                          onChanged: (SourceOptionType value) {},
                        ),
                        const SizedBox(height: 5),
                        BuildRowPropertyWidget(
                          label: "Connection",
                          value: "Value",
                          options: <String>["Value"],
                          onOptionSelected: (int value) {
                            //
                          },
                        ),
                        const SizedBox(height: 5),
                        BuildRowPropertyWidget(
                          label: "Name",
                          value: "Value",
                          options: <String>["Value"],
                          onOptionSelected: (int value) {
                            //
                          },
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            // Cancel & Save buttons
                            GestureDetector(
                              onTap: Navigator.of(context).pop,
                              child: FusionAppText(
                                text: "Cancel",
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            NeumorphicDarkButton(
                              onTap: () {
                                if (state.selectedSources.isEmpty) return FusionToast.error(context, message: "Please select at least one source");
                                if (state.selectedListeningAreaId == null) return FusionToast.error(context, message: "Please select a listening area");

                                context.read<AddSourceViewModel>().onSaveTap(context);
                              },
                              backgroundColor: context.colorScheme.surface,
                              text: "Save",
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
    );
  }
}

// Widget _buildSourcesToolWithMenu({required bool isSelected}) {
//     return GuideShowcaseWrapper(
//       step: GuideShowCaseSteps.systemModeTabs,
//       onHighlightedSpotTap: (TapDownDetails value) {
//         sourcesPopupMenuButtonStateGlobalKey.currentState?.showButtonMenu();
//       },
//       child: PopupMenuButton<SourceData>(
//         key: sourcesPopupMenuButtonStateGlobalKey,
//         onSelected: (SourceData selectedItem) {
//           // Set device type index first
//           serviceLocator<ProjectViewModel>().changeDeviceTypeIndex(1); // Sources index

//           // Create product and set for addition
//           final ProductQueryModel product = ProductQueryModel(
//             name: selectedItem.name,
//             price: 0.0,
//             image: selectedItem.assetPath,
//             type: ProductType.sources,
//             sku: selectedItem.id,
//           );
//           serviceLocator<ProjectViewModel>().setSelectedProductToAdd(product);
//         },
//         constraints: const BoxConstraints(
//           maxHeight: 500,
//           maxWidth: 320,
//         ),
//         color: Colors.white,
//         itemBuilder: (BuildContext context) {
//           return <PopupMenuEntry<SourceData>>[
//             const PopupMenuItem<SourceData>(
//               enabled: false,
//               child: Text(
//                 'MICROPHONES',
//                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
//               ),
//             ),
//             ...SourceData.microphoneItems.map(
//               (SourceData item) => PopupMenuItem<SourceData>(
//                 height: 30,
//                 value: item,
//                 child: Row(
//                   children: <Widget>[
//                     Image.asset(
//                       item.assetPath,
//                       height: 14,
//                       width: 14,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         item.name,
//                         style: const TextStyle(fontSize: 12),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const PopupMenuDivider(),
//             const PopupMenuItem<SourceData>(
//               enabled: false,
//               child: Text(
//                 'MEDIA SOURCES',
//                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
//               ),
//             ),
//             ...SourceData.mediaSourceItems.map(
//               (SourceData item) => PopupMenuItem<SourceData>(
//                 height: 30,
//                 value: item,
//                 child: Row(
//                   children: <Widget>[
//                     Image.asset(
//                       item.assetPath,
//                       height: 14,
//                       width: 14,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         item.name,
//                         style: const TextStyle(fontSize: 12),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ];
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 1.0),
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
//             borderRadius: BorderRadius.circular(6.0),
//             border: Border.all(
//               color: isSelected ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
//               width: 1,
//             ),
//           ),
//           child: Tooltip(
//             message: "Add Sources",
//             child: Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Icon(
//                 Icons.mic,
//                 size: 18.0,
//                 color: isSelected ? _getDarkerShade(Colors.green) : Colors.black54,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
