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
import 'constants.dart';
import 'properties_and_filter_section.dart';
import 'replace_speaker_warning_dialog.dart';

class SpeakerQueryPopup extends StatefulWidget {
  const SpeakerQueryPopup({super.key});

  @override
  State<SpeakerQueryPopup> createState() => SpeakerQueryPopupState();
}

class SpeakerQueryPopupState extends State<SpeakerQueryPopup> {
  Speaker? selectedSpeaker;

  final Products productsApi = Products(baseUrl: AppConfig.awsApiBaseUrl);
  List<SpeakerMountingType> _selectedMountingTypes = <SpeakerMountingType>[];
  List<SpeakerLowFrequency> _selectedLowFrequencies = <SpeakerLowFrequency>[];
  List<SpeakerColor> _selectedColors = <SpeakerColor>[];
  SpeakerWiring? _selectedWiring;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  List<SpeakerProduct>? _speakers;

  void getProducts() async {
    try {
      await productsApi.initialize();
      _speakers = productsApi.speakers;
    } catch (e) {
      _speakers = <SpeakerProduct>[];
    }
    setState(() {});
  }

  List<SpeakerProduct>? get speakers {
    return _speakers;
  }

  // Expand each speaker into color variants so black/white appear as separate entries
  List<MapEntry<SpeakerProduct, String?>> _buildColorVariants(List<SpeakerProduct> items) {
    final List<MapEntry<SpeakerProduct, String?>> variants = <MapEntry<SpeakerProduct, String?>>[];

    for (final SpeakerProduct speakerProduct in items) {
      final bool hasBlack = speakerProduct.assets.getAssetsFor('black').isNotEmpty;
      final bool hasWhite = speakerProduct.assets.getAssetsFor('white').isNotEmpty;

      // If user selected specific colors, emit only those variants
      if (_selectedColors.isNotEmpty) {
        bool emitted = false;
        if (_selectedColors.contains(SpeakerColor.black) && hasBlack) {
          variants.add(MapEntry<SpeakerProduct, String?>(speakerProduct, 'black'));
          emitted = true;
        }
        if (_selectedColors.contains(SpeakerColor.white) && hasWhite) {
          variants.add(MapEntry<SpeakerProduct, String?>(speakerProduct, 'white'));
          emitted = true;
        }
        // If none of the selected colors exist for this product, skip
        if (!emitted) {
          continue;
        }
      } else {
        // No color selection: emit available variants, or a single uncolored entry
        if (hasBlack & hasWhite) {
          variants.addAll(<MapEntry<SpeakerProduct, String?>>[
            MapEntry<SpeakerProduct, String?>(speakerProduct, 'black'),
            MapEntry<SpeakerProduct, String?>(speakerProduct, 'white'),
          ]);
        } else if (hasBlack) {
          variants.add(MapEntry<SpeakerProduct, String?>(speakerProduct, 'black'));
        } else if (hasWhite) {
          variants.add(MapEntry<SpeakerProduct, String?>(speakerProduct, 'white'));
        } else {
          variants.add(MapEntry<SpeakerProduct, String?>(speakerProduct, null));
        }
      }
    }

    return variants;
  }

  List<SpeakerProduct>? _applyFilters(List<SpeakerProduct> items) {
    Iterable<SpeakerProduct> filtered = items;

    // Search filter
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final String hay = '${p.modelName} ${p.modelFamily} ${p.description} ${p.shortDescription ?? ''}'.toLowerCase();
        return hay.contains(query);
      });
    }

    // Mounting filter (multi-select)
    if (_selectedMountingTypes.isNotEmpty) {
      final List<String> keys = _selectedMountingTypes.map((SpeakerMountingType e) => e.displayName.toLowerCase()).toList();
      filtered = filtered.where((SpeakerProduct p) {
        final String mt = (p.mountType ?? '').toLowerCase();
        return keys.any((String k) => mt.contains(k));
      });
    }

    // Wiring filter
    if (_selectedWiring != null) {
      final bool wantHiZ = _selectedWiring == SpeakerWiring.hiZ;
      filtered = filtered.where((SpeakerProduct p) {
        final bool hasHiZ =
            p.isHighImpedanceRated ||
            (p.availableTaps?.taps70V.isNotEmpty == true) ||
            (p.availableTaps?.taps100V.isNotEmpty == true) ||
            p.highImpedanceTaps.isNotEmpty;
        final bool hasLoZ = (p.nominalImpedance != null) || (p.impedance != null);
        return wantHiZ ? hasHiZ : hasLoZ;
      });
    }

    // Low Frequency filter (multi-select)
    if (_selectedLowFrequencies.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        final FrequencyRange? fr = p.frequencyRange;
        final bool isSub =
            p.isSubwoofer || (p.description.toLowerCase().contains('subwoofer') || (p.shortDescription?.toLowerCase().contains('subwoofer') ?? false));

        bool matches = false;
        for (final SpeakerLowFrequency sel in _selectedLowFrequencies) {
          switch (sel) {
            case SpeakerLowFrequency.subwoofer:
              if (isSub) {
                matches = true;
              }
              break;
            case SpeakerLowFrequency.extended:
              if (!isSub && fr != null && fr.low > 0 && fr.low <= 40) {
                matches = true;
              }
              break;
            case SpeakerLowFrequency.fullRange:
              if (!isSub && fr != null && fr.low > 40 && fr.low <= 80) {
                matches = true;
              }
              break;
            case SpeakerLowFrequency.vocal:
              if (!isSub && fr != null && fr.low > 80) {
                matches = true;
              }
              break;
          }
          if (matches) break;
        }
        return matches;
      });
    }

    // Color filter (multi-select)
    if (_selectedColors.isNotEmpty) {
      filtered = filtered.where((SpeakerProduct p) {
        bool match = false;
        for (final SpeakerColor c in _selectedColors) {
          if (c == SpeakerColor.black && p.assets.getAssetsFor('black').isNotEmpty) {
            match = true;
          }
          if (c == SpeakerColor.white && p.assets.getAssetsFor('white').isNotEmpty) {
            match = true;
          }
          if (match) break;
        }
        return match;
      });
    }

    // Venue Type filter from properties panel (Indoor vs Indoor + Outdoor)
    // Uses new products.json fields: environment and is_weather_rated
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    final ListeningArea? la = viewModel.getCurrentSelectedListeningArea();
    if (la != null) {
      final String vt = la.venuType.trim().toLowerCase();
      if (vt == 'indoor') {
        // Indoor: include products that are NOT weather-rated or explicitly indoor environment
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isIndoorEnv = env.contains('indoor');
          return !p.isWeatherRated || isIndoorEnv;
        });
      } else if (vt == 'indoor + outdoor') {
        // Indoor + Outdoor: include products that ARE weather-rated or explicitly outdoor environment
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isOutdoorEnv = env.contains('outdoor');
          return p.isWeatherRated || isOutdoorEnv;
        });
      }
    }

    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    final ListeningArea? currentSelectedListeningArea = projectViewModel.getCurrentSelectedListeningArea();

    final List<Speaker> listeningAreaSpeakers =
        projectViewModel
            .getHardwareForListeningArea(listeningAreaId: currentSelectedListeningArea!.id)
            .whereType<Speaker>()
            .where((Speaker element) => element.pos == null)
            .toList();

    return Container(
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
                  onChanged: (String value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: "Recently Viewed",
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: FusionSvgIcon(
                          icon: "assets/svg/sort.svg",
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: FusionSvgIcon(
                          icon: "assets/svg/filter.svg",
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
                    if (speakers == null) {
                      return const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                      );
                    } else if (speakers!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: FusionAppText(
                            text: 'No products found',
                          ),
                        ),
                      );
                    } else {
                      final List<SpeakerProduct>? filtered = _applyFilters(speakers!);

                      if (filtered!.isEmpty) {
                        final bool isSearchActive = _searchQuery.trim().isNotEmpty;
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
                              final List<MapEntry<SpeakerProduct, String?>> variants = _buildColorVariants(filtered);
                              return ListView.separated(
                                itemCount: variants.length,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                physics: const ClampingScrollPhysics(),
                                separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 0.5),
                                itemBuilder: (BuildContext context, int index) {
                                  final MapEntry<SpeakerProduct, String?> variant = variants[index];
                                  final SpeakerProduct speaker = variant.key;
                                  final String? variantColor = variant.value; // 'black' | 'white' | null

                                  late String? assetImagePath;

                                  if (variantColor == 'black') {
                                    final List<String> urls = speaker.assets.getAssetsFor('black');
                                    assetImagePath = urls.isNotEmpty ? productsApi.getImagePath(urls.first) : null;
                                  } else if (variantColor == 'white') {
                                    final List<String> urls = speaker.assets.getAssetsFor('white');
                                    assetImagePath = urls.isNotEmpty ? productsApi.getImagePath(urls.first) : null;
                                  } else if (speaker.assets.firstAssetUrl != null) {
                                    assetImagePath = productsApi.getImagePath(speaker.assets.firstAssetUrl!);
                                  }

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
                                                          text: '($variantColor)',
                                                          style: context.textTheme.labelSmall?.copyWith(
                                                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(width: 4),
                                                      // info
                                                      FusionArrowPopup(
                                                        content: SizedBox(
                                                          width: 300,
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: <Widget>[
                                                              FusionAppText(
                                                                text: "L 22.4cm | W 14.7cm | H 8.3cm | 9kg", // TODO: hardcoded
                                                                style: context.textTheme.bodySmall?.copyWith(
                                                                  color: context.colorScheme.onSurface,
                                                                ),
                                                              ),

                                                              // GRID VIEW
                                                              Divider(color: context.colorScheme.onSurface.withValues(alpha: 0.2)),
                                                              Builder(
                                                                builder: (BuildContext context) {
                                                                  final String frequencyResponse = () {
                                                                    final FrequencyRange? f = speaker.frequencyRange;
                                                                    if (f == null) return 'N/A';
                                                                    if (f.low == 0 && f.high == 0) return 'N/A';
                                                                    return '${f.low}\u2013${f.high} ${f.unit}';
                                                                  }();

                                                                  final String environment = () {
                                                                    if ((speaker.environment ?? '').isNotEmpty) {
                                                                      return speaker.environment!;
                                                                    }
                                                                    return speaker.isWeatherRated ? 'Weather rated' : 'N/A';
                                                                  }();

                                                                  final String sensitivity = () {
                                                                    final Sensitivity? s = speaker.sensitivity;
                                                                    if (s == null || s.at.isEmpty) return 'N/A';
                                                                    return s.at.map((MeasurementValue e) => '${e.value} ${s.unit} @ ${e.key}').join(', ');
                                                                  }();

                                                                  final String maxSpl = () {
                                                                    final MaxSpl? m = speaker.maxSpl;
                                                                    if (m == null || m.at.isEmpty) return 'N/A';
                                                                    return m.at.map((MeasurementValue e) => '${e.value} ${m.unit} @ ${e.key}').join(', ');
                                                                  }();

                                                                  final String peakPower = () {
                                                                    final PowerHandling? p = speaker.powerHandling;
                                                                    if (p == null) return 'N/A';
                                                                    return '${p.peak} ${p.unit}';
                                                                  }();

                                                                  final String longTermPower = () {
                                                                    final PowerHandling? p = speaker.powerHandling;
                                                                    if (p == null) return 'N/A';
                                                                    return '${p.longTermRms} ${p.unit}';
                                                                  }();

                                                                  final String powerHandlingSummary = () {
                                                                    final PowerHandling? p = speaker.powerHandling;
                                                                    if (p == null) return 'N/A';
                                                                    return 'RMS ${p.longTermRms} ${p.unit}, Peak ${p.peak} ${p.unit}';
                                                                  }();

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
                                                final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
                                                final String listeningAreaId = currentSelectedListeningArea.id;
                                                final FloorModel currentFloor = projectViewModel.currentFloor;

                                                final String newSku = speaker.skus.first.toString();

                                                // If speakers already exist in this listening area, enforce single type
                                                if (listeningAreaSpeakers.isNotEmpty) {
                                                  final String existingSku = listeningAreaSpeakers.first.speakerSKU;

                                                  if (existingSku != newSku) {
                                                    final String existingName = listeningAreaSpeakers.first.name;
                                                    final bool? confirm = await ReplaceSpeakersWarningDialog.show(
                                                      context,
                                                      listeningAreaName: currentSelectedListeningArea.name,
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
                                                projectViewModel.addHardware(
                                                  hardware: projectViewModel.fromSpeakerProductModel(
                                                    assetImagePath!,
                                                    speaker,
                                                    LocationModel(floorId: currentFloor.id, listeningAreaId: listeningAreaId),
                                                    true,
                                                  ),
                                                );
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
          Expanded(
            child: SpeakerListeningAreaProperties(
              selectedSpeakerMountingTypes: _selectedMountingTypes,
              onMountingChanged: (List<SpeakerMountingType> values) {
                setState(() {
                  _selectedMountingTypes = values;
                });
              },
              selectedLowFrequencies: _selectedLowFrequencies,
              onLowFrequencyChanged: (List<SpeakerLowFrequency> values) {
                setState(() {
                  _selectedLowFrequencies = values;
                });
              },
              selectedColors: _selectedColors,
              onColorChanged: (List<SpeakerColor> values) {
                setState(() {
                  _selectedColors = values;
                });
              },
              selectedWiring: _selectedWiring,
              onWiringChanged: (SpeakerWiring? value) {
                setState(() {
                  _selectedWiring = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
