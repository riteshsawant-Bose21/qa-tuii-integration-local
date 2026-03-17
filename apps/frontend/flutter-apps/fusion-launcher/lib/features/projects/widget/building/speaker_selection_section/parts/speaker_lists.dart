import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/view_model/product_query_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/grid_view.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../view_model/add_speaker_view_model.dart';
import 'constant_enums.dart';

class ProductQuerySpeakerList extends StatelessWidget {
  const ProductQuerySpeakerList({super.key, required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final SpeakerSelectionViewModel speakerSelectionViewModel =
        context.watch<SpeakerSelectionViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SemanticHelper.formControl(
          testId: SemanticHelper.createTestId(
            SemanticTypes.textInput,
            "speaker_search_input",
          ),
          child: NeumorphicDarkTextField(
            controller: searchController,
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
            hintStyle: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.normal,
            ),
            onChanged:
                (String value) =>
                    speakerSelectionViewModel.setSearchQuery(value),
          ),
        ),
        const SizedBox(height: 10),

        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: BlocBuilder<
                SpeakerSelectionViewModel,
                SpeakerSelectionViewModelState
              >(
                builder: (
                  BuildContext context,
                  SpeakerSelectionViewModelState vmState,
                ) {
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

            BlocBuilder<ProductQueryViewModel, ProductQueryViewModelState>(
              buildWhen:
                  (
                    ProductQueryViewModelState previous,
                    ProductQueryViewModelState current,
                  ) => previous.isRefreshing != current.isRefreshing,
              builder: (
                BuildContext context,
                ProductQueryViewModelState productQueryViewModelState,
              ) {
                if (productQueryViewModelState.isRefreshing) {
                  return const CupertinoActivityIndicator(radius: 8);
                } else {
                  return SemanticHelper.button(
                    testId: SemanticHelper.createTestId(
                      SemanticTypes.button,
                      "refresh_products_button",
                    ),
                    child: GestureDetector(
                      onTap: context.read<ProductQueryViewModel>().refresh,
                      child: const Tooltip(
                        message: "Refresh products",
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Icon(
                            LucideIcons.refreshCw200,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(width: 8),
            FusionArrowPopup(
              semanticId: 'sort_products',
              blurAmount: 0,
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter menuSetState) {
                  return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                    builder: (
                      BuildContext context,
                      ProjectViewModelState projectViewModelState,
                    ) {
                      return BlocProvider<SpeakerSelectionViewModel>.value(
                        value: speakerSelectionViewModel,
                        child: BlocBuilder<
                          SpeakerSelectionViewModel,
                          SpeakerSelectionViewModelState
                        >(
                          builder: (
                            BuildContext context,
                            SpeakerSelectionViewModelState vmState,
                          ) {
                            return SizedBox(
                              width: 220,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: 'Sort by',
                                      style: context.textTheme.bodySmall
                                          ?.copyWith(
                                            color:
                                                context.colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...SpeakerSortOption.values.map((
                                      SpeakerSortOption entry,
                                    ) {
                                      final bool selected =
                                          vmState.sortOption == entry;

                                      return SemanticHelper.container(
                                        testId: SemanticHelper.createTestId(
                                          SemanticTypes.container,
                                          "speaker_sort_option_${entry.index}",
                                        ),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            speakerSelectionViewModel
                                                .setSortOption(entry);
                                            menuSetState(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6.0,
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                SemanticHelper.toggle(
                                                  testId: SemanticHelper.createTestId(
                                                    SemanticTypes.toggle,
                                                    "speaker_sort_option_toggle_${entry.index}",
                                                  ),
                                                  value: selected,
                                                  child: Icon(
                                                    selected
                                                        ? Icons.circle
                                                        : Icons
                                                            .radio_button_unchecked,
                                                    size: 14,
                                                    color:
                                                        selected
                                                            ? context
                                                                .colorScheme
                                                                .primary
                                                            : context
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: FusionAppText(
                                                    text: entry.displayName,
                                                    style: context
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              context
                                                                  .colorScheme
                                                                  .onSurface,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                      );
                    },
                  );
                },
              ),
              child: SemanticHelper.button(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.button,
                  "sort_products_button",
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: "Sort products",
                    child: FusionSvgIcon(
                      icon: "assets/svg/sort.svg",
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Divider(
          thickness: 0.5,
          height: 0,
          color: context.colorScheme.strokeLight,
        ),

        BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (
            BuildContext context,
            ProjectViewModelState projectViewModelState,
          ) {
            final List<Speaker> listeningAreaSpeakers =
                speakerSelectionViewModel.getAllPlacedNonPlacedSpeakers();

            return BlocBuilder<
              SpeakerSelectionViewModel,
              SpeakerSelectionViewModelState
            >(
              builder: (
                BuildContext context,
                SpeakerSelectionViewModelState vmState,
              ) {
                final ProductQueryViewModel productQueryViewModel =
                    context.watch<ProductQueryViewModel>();
                final bool isProductsLoading = productQueryViewModel.isLoading;
                final List<SpeakerProduct> speakers =
                    productQueryViewModel.speakers;

                if (isProductsLoading) {
                  return Expanded(
                    child: SemanticHelper.container(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.container,
                        "speaker_products_loading_indicator",
                      ),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CupertinoActivityIndicator(),
                        ),
                      ),
                    ),
                  );
                } else if (speakers.isEmpty) {
                  return SemanticHelper.container(
                    testId: SemanticHelper.createTestId(
                      SemanticTypes.container,
                      "speaker_products_empty_indicator",
                    ),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FusionAppText(
                          text: 'No products found',
                        ),
                      ),
                    ),
                  );
                } else {
                  final List<SpeakerProduct> items = speakerSelectionViewModel
                      .applyFilters(speakers);

                  if (items.isEmpty) {
                    final bool isSearchActive =
                        vmState.searchQuery.trim().isNotEmpty;
                    return Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FusionAppText(
                            text:
                                isSearchActive
                                    ? 'No speakers match your search.'
                                    : 'No products match the selected filters',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Flexible(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: Builder(
                        builder: (BuildContext context) {
                          return ListView.separated(
                            itemCount: items.length,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            physics: const ClampingScrollPhysics(),
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(thickness: 0.5),
                            itemBuilder: (BuildContext context, int index) {
                              final SpeakerProduct product = items[index];

                              final bool isSelected = listeningAreaSpeakers.any(
                                (Speaker sp) =>
                                    sp.productId == product.productId,
                              );

                              return SpeakerCard(
                                index: index,
                                product: product,
                                isSelected: isSelected,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class _SpeakerColorVarient {
  final int productId;
  final SpeakerColor color;
  final String? cachedImagePath;

  const _SpeakerColorVarient({
    required this.productId,
    required this.color,
    required this.cachedImagePath,
  });
}

class SpeakerCard extends StatefulWidget {
  const SpeakerCard({
    super.key,
    required this.index,
    required this.product,
    required this.isSelected,
  });

  final int index;
  final SpeakerProduct product;
  final bool isSelected;

  @override
  State<SpeakerCard> createState() => _SpeakerCardState();
}

class _SpeakerCardState extends State<SpeakerCard> {
  _SpeakerColorVarient? selectedVarient;

  List<_SpeakerColorVarient> get productVarients {
    final SpeakerSelectionViewModel addSpeakerViewModel =
        context.read<SpeakerSelectionViewModel>();
    final Set<SpeakerColor> filterColors =
        addSpeakerViewModel.state.selectedColors;
    final List<_SpeakerColorVarient> varients = <_SpeakerColorVarient>[];

    widget.product.assets.assets.forEach(
      (String key, List<String> values) {
        if (values.isNotEmpty) {
          final String assetImagePath = context
              .read<ProductQueryViewModel>()
              .getImagePath(values.first);
          // log("key: $key : ${values.first}");
          // final String? assetImagePath = context.read<ProductQueryViewModel>().getImagePath(widget.product.productId, key);
          // final String assetImagePath = context.read<ProductQueryViewModel>().cachedImages[widget.product.productId]?[key] ?? '';
          // final String assetImageName = context.read<ProductQueryViewModel>().getImageName(values.first);

          final SpeakerColor speakerColor = SpeakerColor.getValueBasedOnKey(
            key,
          );
          if (filterColors.isEmpty || filterColors.contains(speakerColor)) {
            varients.add(
              _SpeakerColorVarient(
                productId: widget.product.productId,
                color: speakerColor,
                cachedImagePath: assetImagePath,
              ),
            );
          }
        }
      },
    );

    // Selection priority:
    // 1) Keep current selection if still available
    // 2) If filtered colors exist, select a matching variant
    // 3) Fallback to the first available variant
    _SpeakerColorVarient? nextSelection;
    if (selectedVarient != null) {
      final int existingIdx = varients.indexWhere(
        (_SpeakerColorVarient v) => v.color == selectedVarient!.color,
      );
      if (existingIdx != -1) {
        nextSelection = varients[existingIdx];
      }
    }

    if (nextSelection == null && filterColors.isNotEmpty) {
      final int filteredIdx = varients.indexWhere(
        (_SpeakerColorVarient v) => filterColors.contains(v.color),
      );
      if (filteredIdx != -1) {
        nextSelection = varients[filteredIdx];
      }
    }

    nextSelection ??= varients.isNotEmpty ? varients.first : null;

    selectedVarient = nextSelection;

    return varients;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      SpeakerSelectionViewModel,
      SpeakerSelectionViewModelState
    >(
      builder: (BuildContext context, SpeakerSelectionViewModelState state) {
        final double productPrice = context
            .read<ProductQueryViewModel>()
            .getPrice(widget.product.productId);

        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            "speaker_card_${widget.index}",
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: <Widget>[
                    SemanticHelper.container(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.container,
                        "speaker_card_image_${widget.index}",
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Builder(
                          builder: (BuildContext context) {
                            if (selectedVarient?.cachedImagePath == null)
                              return const SizedBox();
                            return Image.asset(
                              selectedVarient!.cachedImagePath!,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Flexible(
                                child: FusionAppText(
                                  semanticId: "speaker_name_${widget.index}",
                                  text: widget.product.modelName,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              FusionArrowPopup(
                                semanticId: 'speaker_card_info',
                                content: SizedBox(
                                  width: 400,
                                  height: 280,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            if (selectedVarient
                                                    ?.cachedImagePath !=
                                                null) ...<Widget>[
                                              Center(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Image.asset(
                                                    selectedVarient!
                                                        .cachedImagePath!,
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
                                                text:
                                                    "L 22.4cm | W 14.7cm | H 8.3cm | 9kg",
                                                style: context
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          context
                                                              .colorScheme
                                                              .onSurface,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        Divider(
                                          color: context.colorScheme.onSurface
                                              .withValues(alpha: 0.2),
                                        ),
                                        Builder(
                                          builder: (BuildContext context) {
                                            final String frequencyResponse =
                                                SpeakerSelectionViewModel.formatFrequencyRange(
                                                  widget.product.frequencyRange,
                                                );
                                            final String environment =
                                                SpeakerSelectionViewModel.computeEnvironment(
                                                  widget.product.environment,
                                                  isWeatherRated:
                                                      widget
                                                          .product
                                                          .isWeatherRated,
                                                );
                                            final String sensitivity =
                                                SpeakerSelectionViewModel.formatSensitivity(
                                                  widget.product.sensitivity,
                                                );
                                            final String maxSpl =
                                                SpeakerSelectionViewModel.formatMaxSpl(
                                                  widget.product.maxSpl,
                                                );
                                            final PowerHandling? p =
                                                widget.product.powerHandling;
                                            final String peakPower =
                                                SpeakerSelectionViewModel.formatPowerValue(
                                                  value: p?.peak,
                                                  unit: p?.unit,
                                                );
                                            final String longTermPower =
                                                SpeakerSelectionViewModel.formatPowerValue(
                                                  value: p?.longTermRms,
                                                  unit: p?.unit,
                                                );
                                            final String powerHandlingSummary =
                                                SpeakerSelectionViewModel.formatPowerSummary(
                                                  longTermRms: p?.longTermRms,
                                                  peak: p?.peak,
                                                  unit: p?.unit,
                                                );

                                            final Map<String, String>
                                            details = <String, String>{
                                              'Mounting':
                                                  widget.product.mountType ??
                                                  'N/A',
                                              'Frequency Response':
                                                  frequencyResponse,
                                              'Environment': environment,
                                              'HF Size': 'N/A',
                                              'Power Handling':
                                                  powerHandlingSummary,
                                              'LF Size': 'N/A',
                                              'Sensitivity': sensitivity,
                                              'Max. SPL': maxSpl,
                                              'Peak Power': peakPower,
                                              'Long Term Power': longTermPower,
                                            };

                                            final List<Widget>
                                            children = <Widget>[
                                              ...details.entries.map((
                                                MapEntry<String, String> entry,
                                              ) {
                                                final String key = entry.key;
                                                final String value =
                                                    entry.value;

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    FusionAppText(
                                                      text: key,
                                                      style: context
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                          ),
                                                    ),
                                                    FusionAppText(
                                                      text: value,
                                                      style: context
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: context
                                                                .colorScheme
                                                                .onSurface
                                                                .withAlpha(128),
                                                          ),
                                                    ),
                                                  ],
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
                                child: SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.container,
                                    "speaker_card_info_${widget.index}",
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Icon(
                                      LucideIcons.info200,
                                      size: 12,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          FusionAppText(
                            semanticId: "speaker_card_price_${widget.index}",
                            text: "\$$productPrice",
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.normal,
                              color: context.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            runAlignment: WrapAlignment.start,
                            children: <Widget>[
                              ...productVarients.map((
                                _SpeakerColorVarient colorVarient,
                              ) {
                                final bool isSelected =
                                    selectedVarient?.color ==
                                    colorVarient.color;

                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.container,
                                    "speaker_color_varient_${widget.index}_${colorVarient.color.name}",
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      selectedVarient = colorVarient;
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.elevation3,
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: Row(
                                        spacing: 4,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          FusionAppText(
                                            text:
                                                colorVarient.color.displayName,
                                            style: context.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      context
                                                          .colorScheme
                                                          .textPrimary,
                                                  fontSize: 7,
                                                ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check,
                                              size: 12,
                                              color:
                                                  context
                                                      .colorScheme
                                                      .textPrimary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.button,
                        "add_speaker_button_${widget.index}",
                      ),
                      child: FusionNeumorphicButton(
                        semanticId: 'add_speaker_button',
                        height: 24,
                        width: 24,
                        borderRadius: 6,
                        color:
                            widget.isSelected
                                ? FusionDarkColorPallette.green20
                                : context.colorScheme.elevation2,
                        child: Icon(
                          LucideIcons.plus,
                          size: 12,
                          color:
                              widget.isSelected
                                  ? Colors.white
                                  : context.colorScheme.textPrimary,
                        ),
                        // text: "Add Speaker",
                        onTap: () {
                          context
                              .read<SpeakerSelectionViewModel>()
                              .addOrReplaceSpeaker(
                                context: context,
                                cachedImagePath:
                                    selectedVarient?.cachedImagePath,
                                product: widget.product,
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
