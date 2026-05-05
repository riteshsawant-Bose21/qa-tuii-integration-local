part of '../speaker_selection_popup_2.dart';

class SpeakerSelectionRightContent extends StatelessWidget {
  const SpeakerSelectionRightContent({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
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

                  final List<SpeakerProduct> selectedFullRangeSpeakers = state.selectedSpeakers.where((SpeakerProduct spkr) => !spkr.isSubwoofer).toList();

                  final List<SpeakerProduct> selectedSubwooferSpeakers = state.selectedSpeakers.where((SpeakerProduct spkr) => spkr.isSubwoofer).toList();

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (selectedFullRangeSpeakers.isNotEmpty) ...<Widget>[
                          FusionAppText(
                            text: "MID-HIGH",
                            style: context.textTheme.l2SemiBold.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),

                          ListView.builder(
                            itemCount: selectedFullRangeSpeakers.length,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              return _SpeakerCard(
                                index: index,
                                product: selectedFullRangeSpeakers[index],
                                showSpecs: false,
                                shouldRemove: true,
                              );
                            },
                          ),
                        ],

                        Divider(color: context.colorScheme.strokeLight),

                        if (selectedSubwooferSpeakers.isNotEmpty) ...<Widget>[
                          FusionAppText(
                            text: "SUBWOOFER",
                            style: context.textTheme.l2SemiBold.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),

                          ListView.builder(
                            itemCount: selectedSubwooferSpeakers.length,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemBuilder: (BuildContext context, int index) {
                              return _SpeakerCard(
                                index: index,
                                product: selectedSubwooferSpeakers[index],
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
            const SizedBox(height: 20),

            FusionContainer(
              borderRadius: 8,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _ModeChip(
                        label: "Mid-High",
                        selected: true,
                        padding: const EdgeInsets.all(6),
                        borderRadius: 6,
                        textStyle: context.textTheme.b3Medium,
                        onTap: () {
                          //
                        },
                      ),
                    ),

                    Expanded(
                      child: _ModeChip(
                        label: "Subwoofer",
                        padding: const EdgeInsets.all(6),
                        selected: false,
                        borderRadius: 6,
                        textStyle: context.textTheme.b3Medium,
                        onTap: () {
                          //
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _SearchBar(
              controller: context.read<SpeakerSelectionViewModel>().searchController,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<ProductQueryViewModel, ProductQueryViewModelState>(
                builder: (BuildContext context, ProductQueryViewModelState state) {
                  final List<SpeakerProduct>? speakers = state.products?.speakers;

                  if (speakers == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (speakers.isEmpty) {
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
                      separatorBuilder: (_, __) => Divider(height: 1, color: context.colorScheme.strokeLight),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakerCard extends StatelessWidget {
  const _SpeakerCard({
    required this.index,
    required this.product,
    this.showSpecs = true,
    this.shouldRemove = false,
  });

  final int index;
  final SpeakerProduct product;
  final bool showSpecs;
  final bool shouldRemove;

  String _formatUsd(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String wholeWithCommas = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match match) => ',');
    return '\$$wholeWithCommas.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ProductQueryViewModel productsVm = context.watch<ProductQueryViewModel>();
    final double productPrice = productsVm.getPrice(product.productId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
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
                  path: productsVm.getProductImage(product.productId),
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
                          selected: true,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _ColorModeChip(
                          label: 'WHITE',
                          selected: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
                builder: (BuildContext context, SpeakerSelectionVmState state) {
                  final bool isSelected = state.selectedSpeakers.isNotEmpty;

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
                            : isSelected
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
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // TODO: SHARATH - PENDING
                  FusionAppText(
                    text: 'Show Specifications',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: context.colorScheme.iconDefault,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ColorModeChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return NeumorphicDarkTextField(
      controller: controller,
      hintText: "Search speakers",
      // variant: FusionFieldVariant.neumorphic,
      prefix: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          LucideIcons.search200,
          color: context.colorScheme.iconDefault,
        ),
      ),
      suffix: SemanticHelper.button(
        testId: SemanticHelper.createTestId(SemanticTypes.button, "sort_products_button"),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
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
  const _SpecGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SpecItem(label: 'L x W x H', value: '22.4cm | 14.7cm | 8.3cm'),
              _SpecItem(label: 'Mounting', value: 'Surface'),
              _SpecItem(label: 'Environment', value: 'Indoor'),
              _SpecItem(label: 'Power Handling', value: 'RMS 100 W, Peak 200 W'),
              _SpecItem(label: 'Sensitivity', value: '86 dB @ 1W @ 1m'),
              _SpecItem(label: 'Peak Power', value: '200 Watts'),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SpecItem(label: 'Frequency Response', value: '60-20000 Hz'),
              _SpecItem(label: 'HF Size', value: 'N/A'),
              _SpecItem(label: 'LF Size', value: 'N/A'),
              _SpecItem(label: 'Max. SPL', value: '101.0 dB SPL @ continuous'),
              _SpecItem(label: 'Long Term Power', value: '100 Watts'),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.textPlaceholder,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          FusionAppText(
            text: value,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.textPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
