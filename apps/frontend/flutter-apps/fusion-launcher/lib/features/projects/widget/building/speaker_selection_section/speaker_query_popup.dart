import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/grid_view.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:fusion_lib/product_data/products.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';
import 'constant_enums.dart';
import 'properties_and_filter_section.dart';
import 'replace_speaker_warning_dialog.dart';
import 'view_model/view_model.dart';

class SpeakerQueryPopup extends StatefulWidget {
  const SpeakerQueryPopup({super.key});

  @override
  State<SpeakerQueryPopup> createState() => SpeakerQueryPopupState();
}

class SpeakerQueryPopupState extends State<SpeakerQueryPopup> {
  Speaker? selectedSpeaker;
  late final SpeakerSelectionViewModel _vm;
  final Products productsApi = Products(baseUrl: AppConfig.awsApiBaseUrl);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = SpeakerSelectionViewModel();
    // Kick off product loading in ViewModel
    _vm.loadProducts(productsApi);
  }

  @override
  Widget build(BuildContext context) {
    final List<Speaker> listeningAreaSpeakers = _vm.getSpeakersForListeningArea();

    return BlocProvider<SpeakerSelectionViewModel>.value(
      value: _vm,
      child: Container(
        width: 640,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  NeumorphicDarkTextField(
                    controller: _searchController,
                    prefix: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        LucideIcons.search200,
                        color: Colors.grey[500],
                      ),
                    ),
                    borderRadius: 8,
                    contentPadding: const EdgeInsets.all(10),
                    hintText: "Search devices...",
                    hintStyle: context.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.normal),
                    onChanged: (String value) => _vm.setSearchQuery(value),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                          builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                            return FusionAppText(
                              text: vmState.sortOption.displayName,
                              style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.normal,
                                color: context.colorScheme.onSurface,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FusionArrowPopup(
                        blurAmount: 0,
                        content: StatefulBuilder(
                          builder: (BuildContext context, StateSetter menuSetState) {
                            return SizedBox(
                              width: 220,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: 'Sort by',
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...SpeakerSortOption.values.map((SpeakerSortOption entry) {
                                      final SpeakerSelectionViewModelState vmState = context.read<SpeakerSelectionViewModel>().state;
                                      final bool selected = vmState.sortOption == entry;

                                      return GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          context.read<SpeakerSelectionViewModel>().setSortOption(entry);
                                          menuSetState(() {});
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                                          child: Row(
                                            children: <Widget>[
                                              Icon(
                                                selected ? Icons.circle : Icons.radio_button_unchecked,
                                                size: 14,
                                                color: selected ? context.colorScheme.primary : context.colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: FusionAppText(
                                                  text: entry.displayName,
                                                  style: context.textTheme.bodySmall?.copyWith(
                                                    color: context.colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: FusionSvgIcon(
                            icon: "assets/svg/sort.svg",
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    thickness: 0.5,
                    height: 0,
                  ),

                  Builder(
                    builder: (BuildContext context) {
                      final SpeakerSelectionViewModel vm = context.watch<SpeakerSelectionViewModel>();
                      final List<SpeakerProduct>? speakers = vm.state.speakers;
                      if (speakers == null) {
                        return const Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CupertinoActivityIndicator(),
                            ),
                          ),
                        );
                      } else if (speakers.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: FusionAppText(
                              text: 'No products found',
                            ),
                          ),
                        );
                      } else {
                        final List<SpeakerProduct> filtered = vm.applyFilters();

                        if (filtered.isEmpty) {
                          final bool isSearchActive = vm.state.searchQuery.trim().isNotEmpty;
                          return Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: FusionAppText(
                                  text: isSearchActive ? 'No speakers match your search.' : 'No products match the selected filters',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Flexible(
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: Builder(
                              builder: (BuildContext context) {
                                final List<SpeakerColorVarientModel> variants = vm.buildColorVariantModels(vm.sortProducts(filtered), productsApi);
                                return ListView.separated(
                                  itemCount: variants.length,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  physics: const ClampingScrollPhysics(),
                                  separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 0.5),
                                  itemBuilder: (BuildContext context, int index) {
                                    final SpeakerColorVarientModel variant = variants[index];
                                    final SpeakerProduct speaker = variant.product;
                                    final SpeakerColor? variantColor = variant.variantColor;
                                    final String? assetImagePath = variant.assetImagePath;

                                    final bool isSelected = listeningAreaSpeakers.any((Speaker element) => element.speakerSKU == speaker.skus.first.toString());

                                    return Container(
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
                                              Container(
                                                width: 40,
                                                height: 40,
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Builder(
                                                  builder: (BuildContext context) {
                                                    if (assetImagePath == null) {
                                                      return const SizedBox();
                                                    }

                                                    return Image.asset(
                                                      assetImagePath,
                                                      fit: BoxFit.contain,
                                                    );
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Row(
                                                      children: <Widget>[
                                                        Flexible(
                                                          child: FusionAppText(
                                                            text: speaker.modelFamily,
                                                            style: context.textTheme.labelSmall?.copyWith(
                                                              fontWeight: FontWeight.bold,
                                                              color: context.colorScheme.onSurface,
                                                            ),
                                                          ),
                                                        ),
                                                        if (variantColor != null) ...<Widget>[
                                                          const SizedBox(width: 6),
                                                          FusionAppText(
                                                            text: '(${variantColor.displayName})',
                                                            style: context.textTheme.labelSmall?.copyWith(
                                                              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                                            ),
                                                          ),
                                                        ],
                                                        const SizedBox(width: 4),
                                                        // info
                                                        FusionArrowPopup(
                                                          content: SizedBox(
                                                            width: 400,
                                                            height: 280,
                                                            child: SingleChildScrollView(
                                                              padding: const EdgeInsets.all(16),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: <Widget>[
                                                                  Row(
                                                                    children: <Widget>[
                                                                      if (assetImagePath != null) ...<Widget>[
                                                                        Center(
                                                                          child: ClipRRect(
                                                                            borderRadius: BorderRadius.circular(4),
                                                                            child: Image.asset(
                                                                              assetImagePath,
                                                                              width: 36,
                                                                              height: 36,
                                                                              fit: BoxFit.cover,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                      ],
                                                                      Expanded(
                                                                        child: FusionAppText(
                                                                          text: "L 22.4cm | W 14.7cm | H 8.3cm | 9kg", // TODO: hardcoded
                                                                          style: context.textTheme.bodySmall?.copyWith(
                                                                            color: context.colorScheme.onSurface,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),

                                                                  // GRID VIEW
                                                                  Divider(color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
                                                                  Builder(
                                                                    builder: (BuildContext context) {
                                                                      final String frequencyResponse = SpeakerSelectionViewModel.formatFrequencyRange(
                                                                        speaker.frequencyRange,
                                                                      );
                                                                      final String environment = SpeakerSelectionViewModel.computeEnvironment(
                                                                        speaker.environment,
                                                                        isWeatherRated: speaker.isWeatherRated,
                                                                      );
                                                                      final String sensitivity = SpeakerSelectionViewModel.formatSensitivity(
                                                                        speaker.sensitivity,
                                                                      );
                                                                      final String maxSpl = SpeakerSelectionViewModel.formatMaxSpl(speaker.maxSpl);
                                                                      final PowerHandling? p = speaker.powerHandling;
                                                                      final String peakPower = SpeakerSelectionViewModel.formatPowerValue(
                                                                        value: p?.peak,
                                                                        unit: p?.unit,
                                                                      );
                                                                      final String longTermPower = SpeakerSelectionViewModel.formatPowerValue(
                                                                        value: p?.longTermRms,
                                                                        unit: p?.unit,
                                                                      );
                                                                      final String powerHandlingSummary = SpeakerSelectionViewModel.formatPowerSummary(
                                                                        longTermRms: p?.longTermRms,
                                                                        peak: p?.peak,
                                                                        unit: p?.unit,
                                                                      );

                                                                      final Map<String, String> details = <String, String>{
                                                                        'Mounting': speaker.mountType ?? 'N/A',
                                                                        'Frequency Response': frequencyResponse,
                                                                        'Environment': environment,
                                                                        'HF Size': 'N/A', // TODO: hardcoded
                                                                        'Power Handling': powerHandlingSummary,
                                                                        'LF Size': 'N/A', // TODO: hardcoded
                                                                        'Sensitivity': sensitivity,
                                                                        'Max. SPL': maxSpl,
                                                                        'Peak Power': peakPower,
                                                                        'Long Term Power': longTermPower,
                                                                      };

                                                                      final List<Widget> children = <Widget>[
                                                                        ...details.entries.map((MapEntry<String, String> entry) {
                                                                          final String key = entry.key;
                                                                          final String value = entry.value;

                                                                          return GestureDetector(
                                                                            onTap: () {
                                                                              // selectedSpeaker = selectedSpeaker == speaker ? null : speaker;
                                                                              // setState(() {});
                                                                            },
                                                                            behavior: HitTestBehavior.translucent,
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: <Widget>[
                                                                                FusionAppText(
                                                                                  text: key,
                                                                                  style: context.textTheme.bodySmall?.copyWith(
                                                                                    fontWeight: FontWeight.normal,
                                                                                  ),
                                                                                ),
                                                                                FusionAppText(
                                                                                  text: value,
                                                                                  style: context.textTheme.bodySmall?.copyWith(
                                                                                    fontWeight: FontWeight.normal,
                                                                                    color: context.colorScheme.onSurface.withAlpha(128),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        }),
                                                                      ];

                                                                      return BuildingPageGridView(
                                                                        width: 140,
                                                                        children: children,
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            LucideIcons.info200,
                                                            size: 12,
                                                            color: context.colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    FusionAppText(
                                                      text: "\$290.00", // TODO: hardcoded
                                                      style: context.textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.normal,
                                                        color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              NeumorphicDarkButton(
                                                height: 24,
                                                width: 24,
                                                borderRadius: 6,
                                                backgroundColor: isSelected ? FusionDarkColorPallette.green20 : null,
                                                child: Icon(
                                                  LucideIcons.plus,
                                                  size: 12,
                                                  color: context.colorScheme.onSurface,
                                                ),
                                                onTap: () async {
                                                  final ListeningArea? currentSelectedListeningArea = _vm.currentSelectedListeningArea;

                                                  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

                                                  final String newSku = speaker.skus.first.toString();

                                                  // If speakers already exist in this listening area, enforce single type
                                                  if (listeningAreaSpeakers.isNotEmpty) {
                                                    final String existingSku = listeningAreaSpeakers.first.speakerSKU;

                                                    if (existingSku != newSku) {
                                                      final String existingName = listeningAreaSpeakers.first.name;
                                                      final bool? confirm = await ReplaceSpeakersWarningDialog.show(
                                                        context,
                                                        listeningAreaName: currentSelectedListeningArea?.name ?? '',
                                                        existingSpeakerName: existingName,
                                                        currentSpeakerName: speaker.modelFamily,
                                                      );

                                                      if (confirm != true) return;

                                                      // Remove all existing speakers in the listening area (no autosave per item)
                                                      for (final Speaker s in listeningAreaSpeakers) {
                                                        projectViewModel.removeHardware(hardwareId: s.id, autoSave: false);
                                                      } // TODO: harcoded. ASK api from MAHESH to replace speakers.
                                                    }
                                                  }

                                                  // Add selected (either same type or replacing after confirm)
                                                  projectViewModel.addHardware(hardware: variant.speaker);
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SpeakerListeningAreaProperties()),
          ],
        ),
      ),
    );
  }
}
