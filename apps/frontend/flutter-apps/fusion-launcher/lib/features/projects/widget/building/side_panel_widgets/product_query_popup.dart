import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/dashboard/presentation/widgets/project_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:fusion_lib/product_data/products.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';

class ProductQueryPopup extends StatelessWidget {
  const ProductQueryPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
        final String? currentSelectedListeningAreaId = projectViewModel.currentSelectedListeningAreaId;

        if (currentSelectedListeningAreaId == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: "SPEAKERS",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ),

                    PopupMenuButton<String>(
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,
                      tooltip: 'Add sources',
                      padding: EdgeInsets.zero,
                      menuPadding: EdgeInsets.zero,
                      clipBehavior: Clip.none,
                      offset: const Offset(45, 0),
                      constraints: const BoxConstraints(minWidth: 1000),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Icon(
                          LucideIcons.plus200,
                          size: 14,
                          color: Theme.of(context).colorScheme.fusionTextViewColor,
                        ),
                      ),
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            enabled: false,
                            padding: EdgeInsets.zero,
                            child: Theme(
                              data: ThemeData.dark(),
                              child: const _PopUpWidget(),
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ),

              BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                builder: (BuildContext context, ProjectViewModelState state) {
                  final String? listeningAreaId = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId;

                  if (listeningAreaId == null) return const SizedBox.shrink();

                  final ListeningArea listeningArea = serviceLocator<ProjectViewModel>().getListeningArea(areaId: listeningAreaId);

                  final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(
                    listeningAreaId: listeningAreaId,
                  );
                  final List<Speaker> speakers = allHardware.whereType<Speaker>().where((Speaker element) => element.pos == null).toList();

                  if (speakers.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              LucideIcons.chevronDown200,
                              size: 16,
                              color: context.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            FusionAppText(
                              text: listeningArea.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (speakers.isNotEmpty) ...<Widget>[
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Image.asset(speakers.first.assetImagePath),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FusionAppText(
                                    text: speakers.first.name,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.minus200,
                                  size: 12,
                                  color: context.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                FusionAppText(
                                  text: "${speakers.length}",
                                  style: context.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  LucideIcons.plus200,
                                  size: 12,
                                  color: context.colorScheme.onSurface,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PopUpWidget extends StatefulWidget {
  const _PopUpWidget();

  @override
  State<_PopUpWidget> createState() => _PopUpWidgetState();
}

class _PopUpWidgetState extends State<_PopUpWidget> {
  Speaker? selectedSpeaker;

  final Products productsApi = Products(baseUrl: 'http://localhost:8080');
  _MountingType? _selectedMountingType;
  _LowFrequency? _selectedLowFrequency;
  _Color? _selectedColor;
  _Wiring? _selectedWiring;
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

    // Mounting filter
    if (_selectedMountingType != null) {
      final String key = _selectedMountingType!.displayName.toLowerCase();
      filtered = filtered.where((SpeakerProduct p) {
        final String mt = (p.mountType ?? '').toLowerCase();
        return mt.contains(key);
      });
    }

    // Wiring filter
    if (_selectedWiring != null) {
      final bool wantHiZ = _selectedWiring == _Wiring.hiZ;
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

    // Low Frequency filter
    if (_selectedLowFrequency != null) {
      filtered = filtered.where((SpeakerProduct p) {
        final FrequencyRange? fr = p.frequencyRange;
        final bool isSub =
            p.isSubwoofer || (p.description.toLowerCase().contains('subwoofer') || (p.shortDescription?.toLowerCase().contains('subwoofer') ?? false));

        switch (_selectedLowFrequency!) {
          case _LowFrequency.subwoofer:
            return isSub;
          case _LowFrequency.extended:
            if (isSub) return false;
            if (fr == null) return false;
            return fr.low > 0 && fr.low <= 40; // very low extension
          case _LowFrequency.fullRange:
            if (isSub) return false;
            if (fr == null) return false;
            return fr.low > 40 && fr.low <= 80;
          case _LowFrequency.vocal:
            if (isSub) return false;
            if (fr == null) return false;
            return fr.low > 80; // limited low extension
        }
      });
    }

    // Color filter (best-effort from text fields)
    if (_selectedColor != null) {
      filtered = filtered.where((SpeakerProduct p) {
        if (_selectedColor == _Color.black) return p.assets.getAssetsFor(_Color.black.name).isNotEmpty;
        if (_selectedColor == _Color.white) return p.assets.getAssetsFor(_Color.white.name).isNotEmpty;
        return false;
      });
    }

    // Venue Type filter from properties panel (Indoor vs Indoor + Outdoor)
    // Uses environment/isWeatherRated fields to refine results.
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();
    final ListeningArea? la = viewModel.getCurrentSelectedListeningArea();
    if (la != null) {
      final String vt = la.venuType.toLowerCase();
      if (vt.contains('indoor')) {
        // Indoor: prefer non-weather-rated or explicitly indoor environment
        filtered = filtered.where((SpeakerProduct p) {
          final String env = (p.environment ?? '').toLowerCase();
          final bool isIndoorEnv = env.contains('indoor');
          return !p.isWeatherRated || isIndoorEnv;
        });
      } else if (vt.contains('indoor') && vt.contains('outdoor')) {
        // TODO: hardcoded. ASK WITH SUHAS
        // Indoor + Outdoor (or outdoor): prefer weather-rated or env mentioning outdoor
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
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
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
                          child: ListView.separated(
                            itemCount: filtered.length,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            physics: const ClampingScrollPhysics(),
                            separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 0.5),
                            itemBuilder: (BuildContext context, int index) {
                              final SpeakerProduct speaker = filtered[index];

                              late String? assetImagePath;

                              if (_selectedColor == _Color.black) {
                                assetImagePath = productsApi.getImagePath(speaker.assets.getAssetsFor(_Color.black.name).first);
                              } else if (_selectedColor == _Color.white) {
                                assetImagePath = productsApi.getImagePath(speaker.assets.getAssetsFor(_Color.white.name).first);
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
                                                              // TODO: hardcoded
                                                              final Map<String, String> details = <String, String>{
                                                                "Mounting": "Surface",
                                                                "Frequency Response": "speaker",
                                                                "Environment": "speaker",
                                                                "HF Size": "speaker",
                                                                "Power Handling": "speaker",
                                                                "LF Size": "speaker",
                                                                "Sensitivity": "speaker",
                                                                "Max. SPL": "speaker",
                                                                "Peak Power": "speaker",
                                                                "Long Term Power": "speaker",
                                                              };

                                                              final List<Widget> children = <Widget>[
                                                                ...details.keys.map((String key) {
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
                                                                          text: key,
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

                                                              return _CustomGrid(children: children);
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

                                                print(confirm);

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
            child: _ListeningAreaProperties(
              selectedMountingType: _selectedMountingType,
              onMountingChanged: (_MountingType? value) {
                setState(() {
                  _selectedMountingType = value;
                });
              },
              selectedLowFrequency: _selectedLowFrequency,
              onLowFrequencyChanged: (_LowFrequency? value) {
                setState(() {
                  _selectedLowFrequency = value;
                });
              },
              selectedColor: _selectedColor,
              onColorChanged: (_Color? value) {
                setState(() {
                  _selectedColor = value;
                });
              },
              selectedWiring: _selectedWiring,
              onWiringChanged: (_Wiring? value) {
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

class _DropDown extends StatefulWidget {
  final String? value;
  final String? hintText;
  final List<String> options;
  final ValueChanged<String> onSelect;

  const _DropDown({
    this.value,
    this.hintText,
    this.options = const <String>[],
    required this.onSelect,
  });

  @override
  State<_DropDown> createState() => __DropDownState();
}

class __DropDownState extends State<_DropDown> {
  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          popupMenuTheme: const PopupMenuThemeData(
            color: Color(0xFFF5F5F5),
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
          splashColor: Colors.transparent, // Disable ripple
          highlightColor: Colors.transparent, // Disable tap highlight
          hoverColor: Colors.transparent, // Disable hover color
        ),
        child: PopupMenuButton<String>(
          color: context.colorScheme.surfaceContainer,
          shadowColor: Colors.transparent,
          position: PopupMenuPosition.under,
          tooltip: '',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          offset: const Offset(0, 10),
          padding: EdgeInsets.zero,
          menuPadding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                enabled: false,
                height: 50,
                padding: const EdgeInsets.all(8).copyWith(right: 0),
                child: Builder(
                  builder: (BuildContext context) {
                    if (widget.options.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FusionAppText(
                          text: "No options available",
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ...widget.options.map(
                          (String value) => GestureDetector(
                            onTap: () {
                              widget.onSelect(value);
                              Navigator.of(context).pop();
                            },
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: FusionAppText(
                                text: value,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ];
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0).copyWith(right: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FusionAppText(
                      text: widget.value ?? widget.hintText ?? 'Select',
                      maxLine: 1,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.colorScheme.onSurface.withValues(alpha: widget.value == null ? 0.5 : 1.0),
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SelectionMode {
  select("Select"),
  suggest("Suggest");

  const _SelectionMode(this.displayName);
  final String displayName;
}

enum _MountingType {
  surface("Surface"),
  ceiling("Ceiling"),
  pendant("Pendant");

  const _MountingType(this.displayName);
  final String displayName;
}

enum _LowFrequency {
  vocal("Vocal"),
  fullRange("Full Range"),
  extended("Extended"),
  subwoofer("Subwoofer");

  const _LowFrequency(this.displayName);
  final String displayName;
}

enum _Color {
  black("Black"),
  white("White");

  const _Color(this.displayName);
  final String displayName;
}

enum _Wiring {
  hiZ("Hi-Z"),
  loZ("Lo-Z");

  const _Wiring(this.displayName);
  final String displayName;
}

class _ListeningAreaProperties extends StatefulWidget {
  final _MountingType? selectedMountingType;
  final ValueChanged<_MountingType?> onMountingChanged;

  final _LowFrequency? selectedLowFrequency;
  final ValueChanged<_LowFrequency?> onLowFrequencyChanged;

  final _Color? selectedColor;
  final ValueChanged<_Color?> onColorChanged;

  final _Wiring? selectedWiring;
  final ValueChanged<_Wiring?> onWiringChanged;

  const _ListeningAreaProperties({
    required this.selectedMountingType,
    required this.onMountingChanged,
    required this.selectedLowFrequency,
    required this.onLowFrequencyChanged,
    required this.selectedColor,
    required this.onColorChanged,
    required this.selectedWiring,
    required this.onWiringChanged,
  });

  @override
  State<_ListeningAreaProperties> createState() => _ListeningAreaPropertiesState();
}

class _ListeningAreaPropertiesState extends State<_ListeningAreaProperties> {
  // final List<String> venueOptions = <String>["Indoor", "Outdoor", "Mixed", "Stadium"];
  final List<String> venueOptions = <String>["Indoor", "Indoor + Outdoor"];
  final List<String> listeningHeightOptions = <String>["Sitting", "Standing", "Custom"];
  // Map display options to actual values
  final Map<String, double> listeningHeightValues = <String, double>{"Sitting": 3.0, "Standing": 6.0, "Custom": 1.0};

  final List<String> splRangeOptions = <String>[
    "Background Music",
    "Paging",
    "Foreground Music",
    "Moderate live sound reinforcement",
    "High-SPL live sound reinforcement",
  ];

  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController listeningAreaController = TextEditingController();
  final TextEditingController customListeningHeightController = TextEditingController();

  final _SelectionMode _selectionMode = _SelectionMode.select;
  final SignalType _selectedSignalType = SignalType.mono;

  @override
  void dispose() {
    ceilingHeightController.dispose();
    listeningAreaController.dispose();
    customListeningHeightController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF292826),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final ListeningArea? selectedListeningArea = viewModel.getCurrentSelectedListeningArea();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: "Select Speaker",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                child: Builder(
                  builder: (BuildContext context) {
                    if (selectedListeningArea == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            FusionAppText(
                              text: "Select listening area\nto view properties",
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onSurface.withAlpha(100),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    ceilingHeightController.text = selectedListeningArea.ceilingHeight;
                    listeningAreaController.text = selectedListeningArea.name;

                    // Determine display value and if custom is selected based on listeningHeight double value
                    String displayValue;
                    bool isCustomListeningHeight = false;

                    if (selectedListeningArea.listeningHeight == 3.0) {
                      displayValue = "Sitting";
                    } else if (selectedListeningArea.listeningHeight == 6.0) {
                      displayValue = "Standing";
                    } else {
                      displayValue = "Custom";
                      isCustomListeningHeight = true;
                      customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(LucideIcons.maximize100, size: 16, color: context.colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: listeningAreaController,
                                  maxLength: 24,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    hintText: 'Enter area name',
                                    hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),

                                  onFieldSubmitted: (String value) {
                                    if (value.trim().isNotEmpty) {
                                      final ListeningArea updatedLA = selectedListeningArea.copyWith(name: value.trim());
                                      viewModel.updateListeningArea(area: updatedLA);
                                    } else {
                                      // Reset to previous value if empty
                                      listeningAreaController.text = selectedListeningArea.name;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          _buildLAPropertyRow(
                            context: context,
                            label: "Type",
                            value: selectedListeningArea.venuType,
                            options: venueOptions,
                            onOptionSelected: (int selectedIndex) {
                              final String selectedType = venueOptions[selectedIndex];
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(venuType: selectedType);
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 5),
                          _buildLAPropertyRow(
                            context: context,
                            label: "Listening Ht",
                            value: displayValue,
                            options: listeningHeightOptions,
                            onOptionSelected: (int selectedIndex) {
                              final String selectedOption = listeningHeightOptions[selectedIndex];
                              final double heightValue = listeningHeightValues[selectedOption] ?? 3.0;

                              final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: heightValue);
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),

                          // Show custom listening height text field if "Custom" is selected
                          if (isCustomListeningHeight) ...<Widget>[
                            const SizedBox(height: 5),
                            _BuildTextField(
                              label: "Custom Height",
                              controller: customListeningHeightController,
                              hintText: "e.g. 4.5",
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                LengthLimitingTextInputFormatter(8), // Limit to reasonable length
                              ],
                              validator: (String? value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final double? parsed = double.tryParse(value);
                                if (parsed == null) return 'Invalid decimal';
                                if (parsed <= 0) return 'Must be > 0';
                                if (parsed > 1000) return 'Too large';
                                return null;
                              },
                              onFieldSubmitted: (String newValue) {
                                final double? parsed = double.tryParse(newValue);

                                if (parsed != null && parsed > 0 && parsed <= 1000) {
                                  final double? customHeight = double.tryParse(newValue);
                                  if (customHeight != null && customHeight > 0) {
                                    final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: customHeight);
                                    viewModel.updateListeningArea(area: updatedLA);
                                  }
                                } else {
                                  // Reset to previous valid value if invalid
                                  customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();

                                  // Show error feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enter a valid decimal value between 0.1 and 1000',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              onChanged: (String value) {
                                // Real-time validation feedback
                                final double? parsed = double.tryParse(value);
                                if (value.isNotEmpty && (parsed == null || parsed <= 0 || parsed > 1000)) {
                                  // Visual feedback for invalid input
                                  customListeningHeightController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: customListeningHeightController.text.length),
                                  );
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 5),
                          _BuildTextField(
                            label: "Ceiling Ht",
                            controller: ceilingHeightController,
                            hintText: "e.g., 10 ft",
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            onFieldSubmitted: (String newValue) {
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(ceilingHeight: newValue);
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 5),
                          _buildLAPropertyRow(
                            context: context,
                            label: "SPL Range",
                            value: _getCurrentSplRange(selectedListeningArea.minSPL, selectedListeningArea.maxSPL),
                            options: splRangeOptions,
                            onOptionSelected: (int selectedIndex) {
                              // Set min/max SPL values based on selection
                              double minSPL, maxSPL;
                              switch (selectedIndex) {
                                case 0: // Background Music
                                  minSPL = 60.0;
                                  maxSPL = 70.0;
                                  break;
                                case 1: // Paging
                                  minSPL = 70.0;
                                  maxSPL = 80.0;
                                  break;
                                case 2: // Foreground Music
                                  minSPL = 75.0;
                                  maxSPL = 90.0;
                                  break;
                                case 3: // Moderate live sound reinforcement
                                  minSPL = 90.0;
                                  maxSPL = 100.0;
                                  break;
                                case 4: // High-SPL live sound reinforcement
                                  minSPL = 100.0;
                                  maxSPL = 120.0;
                                  break;
                                default:
                                  minSPL = 60.0;
                                  maxSPL = 70.0;
                              }

                              final ListeningArea updatedLA = selectedListeningArea.copyWith(
                                minSPL: minSPL,
                                maxSPL: maxSPL,
                              );
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),

                          const SizedBox(height: 5),

                          FusionRadio<SignalType>(
                            selected: _selectedSignalType,
                            options: SignalType.values,
                            labelBuilder: (SignalType signalType) {
                              return FusionAppText(
                                text: signalType.name,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
                              );
                            },
                            onChanged: (SignalType value) {
                              // if (value != null) {
                              //   setState(() {
                              //     _selectedSignalType = value;
                              //   });
                              // }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 5),
              const Divider(thickness: 0.5, height: 0),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          spacing: 10,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ..._SelectionMode.values.map((_SelectionMode mode) {
                              final bool isSelected = _selectionMode == mode;

                              return GestureDetector(
                                onTap: () {
                                  // setState(() {
                                  //   _selectionMode = mode;
                                  // });
                                },
                                child: Container(
                                  width: 89,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? context.colorScheme.surfaceBright : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: FusionAppText(
                                      text: mode.displayName,
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.onSurface,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    FusionAppText(
                      text: 'Mounting',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionRadio<_MountingType>(
                      selected: widget.selectedMountingType,
                      options: _MountingType.values,
                      labelBuilder: (_MountingType mountingType) {
                        return FusionAppText(
                          text: mountingType.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (_MountingType value) {
                        final bool isSame = widget.selectedMountingType == value;
                        widget.onMountingChanged(isSame ? null : value);
                      },
                    ),

                    const SizedBox(height: 24),
                    FusionAppText(
                      text: 'Low Frequency',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionRadio<_LowFrequency>(
                      selected: widget.selectedLowFrequency,
                      options: _LowFrequency.values,
                      labelBuilder: (_LowFrequency lowFrequency) {
                        return FusionAppText(
                          text: lowFrequency.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (_LowFrequency value) {
                        final bool isSame = widget.selectedLowFrequency == value;
                        widget.onLowFrequencyChanged(isSame ? null : value);
                      },
                    ),

                    const SizedBox(height: 24),
                    FusionAppText(
                      text: 'Color',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionRadio<_Color>(
                      selected: widget.selectedColor,
                      options: _Color.values,
                      labelBuilder: (_Color color) {
                        return FusionAppText(
                          text: color.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (_Color value) {
                        final bool isSame = widget.selectedColor == value;
                        widget.onColorChanged(isSame ? null : value);
                      },
                    ),

                    const SizedBox(height: 24),
                    FusionAppText(
                      text: 'Wiring',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionRadio<_Wiring>(
                      selected: widget.selectedWiring,
                      options: _Wiring.values,
                      labelBuilder: (_Wiring wiring) {
                        return FusionAppText(
                          text: wiring.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (_Wiring value) {
                        final bool isSame = widget.selectedWiring == value;
                        widget.onWiringChanged(isSame ? null : value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a dropdown row displaying a property label and its selectable value.
  Widget _buildLAPropertyRow({
    required BuildContext context,
    required String label,
    required String value,
    List<String> options = const <String>[],
    required Function(int selectedIndex) onOptionSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DropDown(
            value: value,
            hintText: "Select type",
            options: options,
            onSelect: (String newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex);
            },
          ),
        ),
      ],
    );
  }

  /// Helper method to determine current SPL range based on min/max values
  String _getCurrentSplRange(double minSPL, double maxSPL) {
    if (minSPL == 60.0 && maxSPL == 70.0) {
      return "Background Music";
    } else if (minSPL == 70.0 && maxSPL == 80.0) {
      return "Paging";
    } else if (minSPL == 75.0 && maxSPL == 90.0) {
      return "Foreground Music";
    } else if (minSPL == 90.0 && maxSPL == 100.0) {
      return "Moderate live sound reinforcement";
    } else if (minSPL == 100.0 && maxSPL == 120.0) {
      return "High-SPL live sound reinforcement";
    } else {
      return "Background Music"; // Default fallback
    }
  }
}

class _BuildTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _BuildTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              hintText: hintText,
              hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
              fillColor: context.colorScheme.surface,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
          ),
        ),
      ],
    );
  }
}

class FusionRadio<T> extends StatelessWidget {
  final T? selected;
  final List<T> options;
  final ValueChanged<T>? onChanged;
  final Widget Function(T option) labelBuilder;

  const FusionRadio({
    super.key,
    required this.selected,
    required this.options,
    required this.labelBuilder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: <Widget>[
        ...options.map((T option) {
          final bool isSelected = selected == option;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged?.call(option),
              behavior: HitTestBehavior.translucent,
              child: Row(
                spacing: 4,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 16,
                    color: context.colorScheme.onSurface,
                  ),

                  labelBuilder(option),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CustomGrid extends StatelessWidget {
  const _CustomGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const double itemWidth = 120;
    const double spacing = 8;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int itemsPerRow = (constraints.maxWidth / itemWidth).floor().clamp(1, 100);

        final double actualWidth = (constraints.maxWidth - (itemsPerRow - 1) * spacing) / itemsPerRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            ...children.map((Widget child) {
              return SizedBox(
                width: actualWidth,
                child: child,
              );
            }),
          ],
        );
      },
    );
  }
}

class ReplaceSpeakersWarningDialog extends StatelessWidget {
  final String listeningAreaName, existingSpeakerName, currentSpeakerName;
  const ReplaceSpeakersWarningDialog({super.key, required this.listeningAreaName, required this.existingSpeakerName, required this.currentSpeakerName});

  static Future<bool?> show(
    BuildContext context, {
    required String listeningAreaName,
    required String existingSpeakerName,
    required String currentSpeakerName,
  }) {
    return Navigator.of(context).push(
      AnimatedBlurDialogRoute<bool>(
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: ReplaceSpeakersWarningDialog(
              listeningAreaName: listeningAreaName,
              existingSpeakerName: existingSpeakerName,
              currentSpeakerName: currentSpeakerName,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.colorScheme.surface,
        border: Border.all(color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.circleAlert200,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FusionAppText(
                    text: "Replace Speakers",
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            FusionAppText(
              text:
                  "The listening area '$listeningAreaName' currently has \"$existingSpeakerName\" speakers. Adding a different speaker will remove the existing ones and add \"$currentSpeakerName\".",

              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FusionAppText(
                        text: "Cancel",
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(true),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FusionAppText(
                        text: "Replace",
                        style: context.textTheme.labelLarge?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // AlertDialog(
    //   title: FusionAppText(text: "Replace Speakers", style: context.textTheme.titleMedium),
    //   content: FusionAppText(
    //     text:
    //         'This listening area currently has "$existingSpeakerName" speakers.\n'
    //         'Adding a different speaker will remove the existing ones and add "$currentSpeakerName".',
    //   ),

    //   actions: <Widget>[
    //     TextButton(
    //       onPressed: () => Navigator.of(context).pop(),
    //       child: const Text('Cancel'),
    //     ),
    //     ElevatedButton(
    //       onPressed: () {
    //         Navigator.of(context).pop(true);
    //       },
    //       child: const Text('Confirm'),
    //     ),
    //   ],
    // );
  }
}
