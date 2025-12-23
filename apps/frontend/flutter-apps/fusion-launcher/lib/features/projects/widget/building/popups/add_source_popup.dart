import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/properties_and_filter_section.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddSourceViewModelState extends Equatable {
  final SourceOption selectedSourceOption;
  final List<Source> selectedSources;

  // Just for UI
  final int totalSourceTypeCount; // initialliy 1

  const AddSourceViewModelState({
    this.selectedSourceOption = SourceOption.singleSource,
    this.selectedSources = const <Source>[],
    this.totalSourceTypeCount = 1,
  });

  AddSourceViewModelState copyWith({
    SourceOption? selectedSourceOption,
    List<Source>? selectedSources,
    int? totalSourceTypeCount,
  }) {
    return AddSourceViewModelState(
      selectedSourceOption: selectedSourceOption ?? this.selectedSourceOption,
      selectedSources: selectedSources ?? this.selectedSources,
      totalSourceTypeCount: totalSourceTypeCount ?? this.totalSourceTypeCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[selectedSourceOption, selectedSources];
}

class AddSourceViewModel extends Cubit<AddSourceViewModelState> {
  AddSourceViewModel() : super(const AddSourceViewModelState());

  void setSourceOption(SourceOption sourceOption) {
    if (sourceOption == state.selectedSourceOption) return;

    final List<Source> sources = List<Source>.from(state.selectedSources);

    if (sourceOption == SourceOption.singleSource) {
      final List<Source> selectedSources = sources.isNotEmpty ? <Source>[sources.first] : <Source>[];
      emit(state.copyWith(selectedSourceOption: sourceOption, selectedSources: selectedSources));
    } else {
      emit(state.copyWith(selectedSourceOption: sourceOption, selectedSources: sources));
    }
  }

  void increaseSelectionSourceCount() {
    emit(state.copyWith(totalSourceTypeCount: state.totalSourceTypeCount + 1));
  }

  void addSource(Source source) {
    final Set<Source> sources = Set<Source>.from(state.selectedSources);
    sources.add(source);
    emit(state.copyWith(selectedSources: sources.toList()));
  }

  void removeSource(Source source) {
    final Set<Source> sources = Set<Source>.from(state.selectedSources);
    sources.remove(source);
    emit(state.copyWith(selectedSources: sources.toList()));
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
      content: BlocProvider<AddSourceViewModel>(
        create: (BuildContext context) => AddSourceViewModel(),
        child: Container(
          width: 320,
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
              BlocBuilder<AddSourceViewModel, AddSourceViewModelState>(
                builder: (BuildContext context, AddSourceViewModelState state) {
                  final AddSourceViewModel addSourceViewModel = context.read<AddSourceViewModel>();
                  final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
                  final List<Source> sources = projectViewModel.sources;

                  return Padding(
                    padding: const EdgeInsetsGeometry.all(16),
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
                          Source? source;
                          try {
                            source = state.selectedSources.elementAt(index);
                          } catch (e) {
                            source = null;
                          }
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.colorScheme.dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Expanded(
                                  child: FusionAppText(
                                    text: "Type",
                                    style: context.textTheme.bodyMedium?.copyWith(
                                      color: context.colorScheme.onSurface,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: BuildingPageDronDown<Source>(
                                    value: source,
                                    items: sources,
                                    labelBuilder: (Source option) {
                                      return FusionAppText(
                                        text: option.name,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      );
                                    },
                                    hintText: "Select type",
                                    onSelect: (Source newValue) {
                                      addSourceViewModel.addSource(newValue);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: NeumorphicDarkButton(
                            onTap: () {
                              addSourceViewModel.increaseSelectionSourceCount();
                            },
                            backgroundColor: context.colorScheme.surface,
                            width: 28,
                            height: 28,
                            borderRadius: 8,
                            child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                          ),
                        ),

                        //
                        const SizedBox(height: 10),
                        BuildRowPropertyWidget(
                          label: "Location",
                          value: "Value",
                          options: <String>["Value"],
                          onOptionSelected: (int value) {
                            //
                          },
                        ),
                        const SizedBox(height: 5),
                        BuildRowPropertyWidget(
                          label: "",
                          value: "Value",
                          options: <String>["Value"],
                          onOptionSelected: (int value) {
                            //
                          },
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: NeumorphicDarkButton(
                            onTap: () {},
                            backgroundColor: context.colorScheme.surface,
                            width: 32,
                            height: 32,
                            borderRadius: 8,
                            child: Icon(LucideIcons.plus200, size: 16, color: context.colorScheme.onSurface),
                          ),
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
                              onTap: () {},
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
            ],
          ),
        ),
      ),
      child: child,
    );
  }
}
