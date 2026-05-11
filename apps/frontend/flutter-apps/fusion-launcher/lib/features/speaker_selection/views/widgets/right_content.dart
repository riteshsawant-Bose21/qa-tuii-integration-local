part of '../speaker_selection_popup.dart';

class SpeakerSelectionRightContent extends StatelessWidget {
  const SpeakerSelectionRightContent({super.key});

  static const List<String> _suggestOrder = <String>[
    'Maximum SPL',
    'Target SPL',
    'Minimum SPL',
  ];

  @override
  Widget build(BuildContext context) {
    final SpeakerSelectionVmState speakerSelectionState = context.watch<SpeakerSelectionViewModel>().state;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24).copyWith(bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 88),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorScheme.strokeLight),
                      ),
                      child: BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
                        buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.selectedSpeakers != current.selectedSpeakers,
                        builder: (BuildContext context, SpeakerSelectionVmState state) {
                          final List<SpeakerProduct> selectedAllSpeakers = state.selectedSpeakers;

                          if (selectedAllSpeakers.isEmpty) {
                            return FusionAppText(
                              text: "No speaker selected yet",
                              style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textPlaceholder),
                            );
                          }

                          final List<SpeakerProduct> fullRangeSpeakers = state.selectedSpeakers.where((SpeakerProduct spkr) => !spkr.isSubwoofer).toList();
                          final List<SpeakerProduct> subwooferSpeakers = state.selectedSpeakers.where((SpeakerProduct spkr) => spkr.isSubwoofer).toList();

                          final bool isSubwooferMode = state.selectModeArgs.useSubwoofer && state.speakerSelectionMode == SpeakerSelectionMode.select;

                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (fullRangeSpeakers.isNotEmpty) ...<Widget>[
                                  if (isSubwooferMode) ...<Widget>[
                                    FusionAppText(
                                      text: "MID-HIGH",
                                      style: context.textTheme.l2SemiBold.copyWith(
                                        color: context.colorScheme.textSecondary,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),
                                  ListView.separated(
                                    itemCount: fullRangeSpeakers.length,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (BuildContext context, int index) {
                                      return _SpeakerCard(
                                        index: index,
                                        product: fullRangeSpeakers[index],
                                        showSpecs: false,
                                        shouldRemove: true,
                                      );
                                    },
                                  ),
                                ],

                                if (fullRangeSpeakers.isNotEmpty && subwooferSpeakers.isNotEmpty) Divider(color: context.colorScheme.strokeLight),

                                if (subwooferSpeakers.isNotEmpty) ...<Widget>[
                                  FusionAppText(
                                    text: "SUBWOOFER",
                                    style: context.textTheme.l2SemiBold.copyWith(
                                      color: context.colorScheme.textSecondary,
                                    ),
                                  ),

                                  const SizedBox(height: 8),
                                  ListView.separated(
                                    itemCount: subwooferSpeakers.length,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (BuildContext context, int index) {
                                      return _SpeakerCard(
                                        index: index,
                                        product: subwooferSpeakers[index],
                                        showSpecs: false,
                                        shouldRemove: true,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    if (speakerSelectionState.speakerSelectionMode == SpeakerSelectionMode.select) ...<Widget>[
                      if (speakerSelectionState.selectModeArgs.useSubwoofer) ...<Widget>[
                        const SizedBox(height: 20),
                        FusionContainer(
                          borderRadius: 8,
                          height: 52,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _ModeChip(
                                    label: "Mid-High",
                                    selected: speakerSelectionState.speakerListTab == 0,
                                    padding: const EdgeInsets.all(6),
                                    borderRadius: 6,
                                    textStyle: context.textTheme.b3Medium,
                                    onTap: () => context.read<SpeakerSelectionViewModel>().setSpeakerListTab(0),
                                  ),
                                ),

                                Expanded(
                                  child: _ModeChip(
                                    label: "Subwoofer",
                                    padding: const EdgeInsets.all(6),
                                    selected: speakerSelectionState.speakerListTab == 1,
                                    borderRadius: 6,
                                    textStyle: context.textTheme.b3Medium,
                                    onTap: () => context.read<SpeakerSelectionViewModel>().setSpeakerListTab(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      /// ================== SEARCH BAR ==================
                      const SizedBox(height: 20),
                      _SearchBar(
                        controller: context.read<SpeakerSelectionViewModel>().searchController,
                      ),

                      /// ================== PRODUCT LIST ==================
                      const SizedBox(height: 20),
                      Expanded(
                        child: BlocBuilder<ProductQueryViewModel, ProductQueryViewModelState>(
                          builder: (BuildContext context, ProductQueryViewModelState productState) {
                            return BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
                              builder: (BuildContext context, SpeakerSelectionVmState speakerSelectionState) {
                                return ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: context.read<SpeakerSelectionViewModel>().searchController,
                                  builder: (BuildContext context, TextEditingValue __, Widget? ___) {
                                    if (productState.products == null) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeCap: StrokeCap.round,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }

                                    final List<SpeakerProduct> speakers = context.read<SpeakerSelectionViewModel>().speakers;

                                    if (speakers.isEmpty) {
                                      return const Center(
                                        child: FusionAppText(
                                          text: "No speakers found",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      );
                                    }

                                    return ClipRRect(
                                      borderRadius: const BorderRadiusGeometry.vertical(top: Radius.circular(12)),
                                      child: ListView.separated(
                                        itemCount: speakers.length,
                                        physics: const ClampingScrollPhysics(),
                                        padding: const EdgeInsets.only(),
                                        separatorBuilder: (_, __) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            child: Divider(height: 0, color: context.colorScheme.strokeLight),
                                          );
                                        },
                                        itemBuilder: (BuildContext context, int index) {
                                          final SpeakerProduct product = speakers[index];

                                          return _SpeakerCard(
                                            index: index,
                                            product: product,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ] else ...<Widget>[
                      const SizedBox(height: 20),
                      Expanded(
                        child: BlocBuilder<ProductQueryViewModel, ProductQueryViewModelState>(
                          builder: (BuildContext context, ProductQueryViewModelState productState) {
                            if (productState.products == null) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeCap: StrokeCap.round,
                                  strokeWidth: 2,
                                ),
                              );
                            }

                            final SpeakerSelectionViewModel vm = context.read<SpeakerSelectionViewModel>();
                            final Map<String, List<SpeakerProduct>> sections = vm.getSuggestedSpeakersByCategory(
                              context.read<ProductQueryViewModel>().speakers,
                            );

                            final List<_SuggestGroupItem> groupedItems = <_SuggestGroupItem>[];
                            for (final String title in _suggestOrder) {
                              final SpeakerProduct? product = (sections[title] ?? const <SpeakerProduct>[]).firstOrNull;
                              if (product == null) continue;

                              final _SuggestGroupItem? existing =
                                  groupedItems.where((_SuggestGroupItem item) => item.product.productId == product.productId).firstOrNull;

                              if (existing != null) {
                                existing.titles.add(title);
                              } else {
                                groupedItems.add(
                                  _SuggestGroupItem(
                                    product: product,
                                    titles: <String>[title],
                                  ),
                                );
                              }
                            }

                            if (groupedItems.isEmpty) {
                              return const Center(
                                child: FusionAppText(
                                  text: "No speakers found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return ListView.separated(
                              physics: const ClampingScrollPhysics(),
                              itemCount: groupedItems.length,
                              separatorBuilder: (_, __) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 0, color: context.colorScheme.strokeLight),
                                );
                              },
                              itemBuilder: (BuildContext context, int index) {
                                final _SuggestGroupItem item = groupedItems[index];
                                final String mergedTitle = item.titles.map((String t) => t.toUpperCase()).join(' / ');

                                return Column(
                                  spacing: 8,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FusionAppText(
                                      text: mergedTitle,
                                      style: context.textTheme.l3Caps.copyWith(
                                        color: context.colorScheme.textBody,
                                        letterSpacing: 0,
                                      ),
                                    ),

                                    _SpeakerCard(
                                      index: index,
                                      product: item.product,
                                      showSpecs: false,
                                      showCompactSuggestSpecs: true,
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_drawer_footer'),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: context.colorScheme.shadowDark, blurRadius: 7, offset: const Offset(2, 2)),
                    BoxShadow(color: context.colorScheme.shadowLight, blurRadius: 7, offset: const Offset(-2, -2)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: FusionAppButton(
                  height: 48,
                  semanticId: 'speaker_drawer_save_button',
                  style: FusionAppButtonStyle.primary,
                  text: "Save",
                  onPressed: () {
                    context.read<SpeakerSelectionViewModel>().save();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestGroupItem {
  final SpeakerProduct product;
  final List<String> titles;

  _SuggestGroupItem({
    required this.product,
    required this.titles,
  });
}

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({
    required this.index,
    required this.product,
    this.showSpecs = true,
    this.shouldRemove = false,
    this.showCompactSuggestSpecs = false,
  });

  final int index;
  final SpeakerProduct product;
  final bool showSpecs;
  final bool shouldRemove;
  final bool showCompactSuggestSpecs;

  String _formatUsd(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String wholeWithCommas = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match match) => ',');
    return '\$$wholeWithCommas.${parts[1]}';
  }

  String _compactSuggestSpecText() {
    final String maxSpl = product.maxSplText;
    final String power = product.powerHandlingSummaryText;

    final bool hasSpl = maxSpl.trim().isNotEmpty && maxSpl != 'N/A';
    final bool hasPower = power.trim().isNotEmpty && power != 'N/A';

    if (hasSpl && hasPower) return 'SPL = $maxSpl, Total Power = $power';
    if (hasSpl) return 'SPL = $maxSpl';
    if (hasPower) return 'Total Power = $power';
    return 'Specifications not available';
  }

  String? _imageForSelectedColor({required SpeakerProduct product, required SpeakerColorOption selectedColor, required ProductQueryViewModel productsVm}) {
    final String selectedKey = selectedColor.name.toLowerCase();
    return productsVm.getProductImage(product.productId, color: selectedKey);
  }

  @override
  Widget build(BuildContext context) {
    final ProductQueryViewModel productsVm = context.watch<ProductQueryViewModel>();
    final SpeakerSelectionViewModel speakerVm = context.watch<SpeakerSelectionViewModel>();
    final SpeakerColorOption selectedColor = speakerVm.state.selectModeArgs.speakerColorOption;
    final double productPrice = productsVm.getPrice(product.productId);
    final String? selectedColorImagePath = _imageForSelectedColor(product: product, selectedColor: selectedColor, productsVm: productsVm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: FusionImageAuto(
                path: selectedColorImagePath,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Icon(
                    LucideIcons.speaker200,
                    size: 30,
                    color: context.colorScheme.iconDefault,
                  );
                },
                fallbackIcon: Icon(
                  LucideIcons.speaker200,
                  size: 30,
                  color: context.colorScheme.iconDefault,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    semanticId: 'speaker_name_$index',
                    text: product.modelName,
                    style: context.textTheme.b3Medium.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FusionAppText(
                    text: _formatUsd(productPrice),
                    style: context.textTheme.l1Bold.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      _ColorModeChip(
                        label: 'BLACK',
                        selected: selectedColor == SpeakerColorOption.black,
                      ),
                      const SizedBox(width: 10),
                      _ColorModeChip(
                        label: 'WHITE',
                        selected: selectedColor == SpeakerColorOption.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
              builder: (BuildContext context, SpeakerSelectionVmState state) {
                final bool isSelectedForSection;
                if (state.selectModeArgs.useSubwoofer && state.speakerSelectionMode == SpeakerSelectionMode.select) {
                  isSelectedForSection = state.selectedSpeakers.any((SpeakerProduct sp) => sp.isSubwoofer == product.isSubwoofer);
                } else {
                  isSelectedForSection = state.selectedSpeakers.isNotEmpty;
                }

                return FusionNeumorphicButton(
                  onTap: () {
                    if (shouldRemove) {
                      context.read<SpeakerSelectionViewModel>().removeSpeaker(speaker: product);
                    } else {
                      context.read<SpeakerSelectionViewModel>().addSpeaker(speaker: product);
                    }
                  },
                  height: 32,
                  width: 90,
                  semanticId: 'speaker_select_btn_$index',
                  text:
                      shouldRemove
                          ? 'Remove'
                          : isSelectedForSection
                          ? "Replace"
                          : 'Select',
                  borderRadius: 8,
                  textStyle: context.textTheme.l1Medium.copyWith(
                    color: context.colorScheme.textPrimary,
                  ),
                );
              },
            ),
          ],
        ),
        if (showSpecs) ...<Widget>[
          const SizedBox(height: 8),
          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.expandSpeakerSpecs != current.expandSpeakerSpecs,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              final SpeakerSelectionViewModel speakerVm = context.read<SpeakerSelectionViewModel>();
              final bool isSpecsExpanded = state.expandSpeakerSpecs.contains(product.productId);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => speakerVm.toggleSpeakerSpecs(product.productId),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          FusionAppText(
                            text: isSpecsExpanded ? 'Hide Specifications' : 'Show Specifications',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colorScheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: isSpecsExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: 14,
                              color: context.colorScheme.iconDefault,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: ClipRect(
                      child: Builder(
                        builder: (BuildContext context) {
                          if (isSpecsExpanded) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 10),
                                Divider(height: 1, color: context.colorScheme.strokeLight),
                                const SizedBox(height: 10),
                                _SpecGrid(product: product),
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        if (showCompactSuggestSpecs) ...<Widget>[
          const SizedBox(height: 8),
          FusionAppText(
            text: _compactSuggestSpecText(),
            style: context.textTheme.l1Regular.copyWith(
              color: context.colorScheme.textBody,
            ),
          ),
        ],
      ],
    );
  }
}

class _ColorModeChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _ColorModeChip({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? context.colorScheme.elevation2 : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colorScheme.elevation2, width: 2),
      ),
      child: FusionAppText(
        text: label,
        style: context.textTheme.l3Caps.copyWith(
          color: context.colorScheme.textBody,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // color: context.colorScheme.shadowDark,
        boxShadow: <BoxShadow>[
          BoxShadow(color: context.colorScheme.shadowDark, blurRadius: 1, offset: const Offset(-2, -2), blurStyle: BlurStyle.inner),
          BoxShadow(color: context.colorScheme.shadowLight, blurRadius: 1, offset: const Offset(2, 2), blurStyle: BlurStyle.inner),
          BoxShadow(color: context.colorScheme.elevation1, blurRadius: 4, blurStyle: BlurStyle.inner),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          spacing: 8,
          children: <Widget>[
            Icon(
              LucideIcons.search200,
              color: context.colorScheme.iconDefault,
            ),

            Expanded(
              child: Align(
                alignment: AlignmentGeometry.centerLeft,
                child: TextFormField(
                  controller: controller,
                  style: context.textTheme.labelLarge,
                  decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: "Search speakers",
                    hoverColor: Colors.transparent,
                    contentPadding: const EdgeInsets.only(),
                    hintStyle: context.textTheme.labelLarge?.copyWith(
                      color: context.colorScheme.textPlaceholder,
                    ),
                  ),
                ),
              ),
            ),

            // ==== SORT ====
            sortOption(context),
          ],
        ),
      ),
    );
  }

  Widget sortOption(BuildContext context) {
    final SpeakerSelectionViewModel speakerSelectionViewModel = context.read<SpeakerSelectionViewModel>();

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, "sort_products_button"),
      child: FusionArrowPopup(
        semanticId: 'sort_products',
        blurAmount: 0,
        backgroundColor: context.colorScheme.elevation2,
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter menuSetState) {
            return BlocProvider<SpeakerSelectionViewModel>.value(
              value: speakerSelectionViewModel,
              child: BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
                builder: (BuildContext context, SpeakerSelectionVmState speakerSelectionState) {
                  return SizedBox(
                    width: 358,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            text: 'Sort by',
                            style: context.textTheme.b3Medium.copyWith(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                children: <Widget>[
                                  ...SpeakerSortOption.values.map((SpeakerSortOption entry) {
                                    final bool selected = speakerSelectionState.sortOption == entry;

                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_sort_option_${entry.index}"),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {
                                            speakerSelectionViewModel.setSortOption(entry);
                                            menuSetState(() {});
                                            Navigator.of(context).pop();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: selected ? context.colorScheme.elevation3 : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                SemanticHelper.toggle(
                                                  testId: SemanticHelper.createTestId(SemanticTypes.toggle, "speaker_sort_option_toggle_${entry.index}"),
                                                  value: selected,
                                                  child: Icon(
                                                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                                    size: 16,
                                                    color: context.colorScheme.primaryWhite,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: FusionAppText(
                                                    text: entry.displayName,
                                                    style: context.textTheme.b3Regular,
                                                  ),
                                                ),
                                              ],
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        child: SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, "sort_products_button"),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Tooltip(
              message: "Sort products",
              child: Icon(
                LucideIcons.arrowDownUp200,
                color: context.colorScheme.iconDefault,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  final SpeakerProduct product;

  const _SpecGrid({required this.product});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> details = <String, String>{
      // 1st column
      'Mounting': product.mountType ?? 'N/A',
      'Environment': product.environmentText,
      'Power Handling': product.powerHandlingSummaryText,
      'Sensitivity': product.sensitivityText,
      'Peak Power': product.peakPowerText,

      // 2nd column
      'Frequency Response': product.frequencyResponseText,
      'HF Sizeßßß': 'N/A',
      'LF Size': 'N/A',
      'Max. SPL': product.maxSplText,
      'Long Term Power': product.longTermPowerText,
    };

    final List<MapEntry<String, String>> entries = details.entries.toList();
    final int midpoint = (entries.length / 2).ceil();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...entries.take(midpoint).map(
                (MapEntry<String, String> entry) {
                  return _SpecItem(
                    label: entry.key,
                    value: entry.value,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...entries.skip(midpoint).map(
                (MapEntry<String, String> entry) {
                  return _SpecItem(
                    label: entry.key,
                    value: entry.value,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: label,
            style: context.textTheme.l2Regular.copyWith(
              color: context.colorScheme.textBody,
            ),
          ),
          const SizedBox(height: 2),
          FusionAppText(
            text: value,
            style: context.textTheme.l1Regular,
          ),
        ],
      ),
    );
  }
}
