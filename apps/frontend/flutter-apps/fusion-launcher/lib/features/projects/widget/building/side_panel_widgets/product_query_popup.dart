import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductQueryPopup extends StatefulWidget {
  const ProductQueryPopup({super.key});

  @override
  State<ProductQueryPopup> createState() => _ProductQueryPopupState();
}

class _ProductQueryPopupState extends State<ProductQueryPopup> {
  @override
  Widget build(BuildContext context) {
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
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    final List<Speaker> speakers = projectViewModel.speakers;

    return Container(
      width: 640,
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
                const Divider(thickness: 0.5),

                Column(
                  children: <Widget>[
                    ...List<Widget>.generate(speakers.length, (int index) {
                      final Speaker speaker = speakers[index];

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                selectedSpeaker = selectedSpeaker == speaker ? null : speaker;
                                setState(() {});
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Row(
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
                                    child: Image.asset(
                                      speaker.assetImagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        FusionAppText(
                                          text: speaker.name,
                                          style: context.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: context.colorScheme.onSurface,
                                          ),
                                        ),

                                        // price
                                        FusionAppText(
                                          text: "\$${speaker.price.toStringAsFixed(2)}",
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
                                    backgroundColor: FusionDarkColorPallette.green20,
                                    child: Icon(
                                      LucideIcons.plus,
                                      size: 12,
                                      color: context.colorScheme.onSurface,
                                    ),
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ),

                            // DETAILS
                            if (selectedSpeaker == speaker)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const SizedBox(height: 4),
                                  FusionAppText(
                                    text: "L 22.4cm | W 14.7cm | H 8.3cm | 9kg",
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),

                                  // GRID VIEW
                                  Builder(
                                    builder: (BuildContext context) {
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

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 5,
                                        ),
                                        itemCount: details.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          final String key = details.keys.elementAt(index);
                                          final String value = details.values.elementAt(index);

                                          return GestureDetector(
                                            onTap: () {
                                              selectedSpeaker = selectedSpeaker == speaker ? null : speaker;
                                              setState(() {});
                                            },
                                            behavior: HitTestBehavior.translucent,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: selectedSpeaker == speaker ? context.colorScheme.primary : Colors.transparent,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: <Widget>[
                                                  Image.asset(
                                                    speaker.assetImagePath,
                                                    height: 14,
                                                    width: 14,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: FusionAppText(
                                                      text: key,
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w500,
                                                        color:
                                                            selectedSpeaker == speaker
                                                                ? context.colorScheme.onSurface
                                                                : context.colorScheme.onSurface.withAlpha(150),
                                                      ),
                                                    ),
                                                  ),
                                                  FusionAppText(
                                                    text: value,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                      color:
                                                          selectedSpeaker == speaker
                                                              ? context.colorScheme.onSurface
                                                              : context.colorScheme.onSurface.withAlpha(150),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF292826),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // Select Speaker
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FusionAppText(
                      text: "Select Speaker",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Divider(thickness: 0.5, height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(LucideIcons.maximize100, size: 16, color: context.colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FusionAppText(
                                text: "Reception_Lounge",
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(LucideIcons.maximize100, size: 16, color: context.colorScheme.onSurface),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _DropDown(
                                onSelect: (String value) {
                                  //
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropDown extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final List<String> options;
  final ValueChanged<String> onSelect;
  final double borderRadius;

  const _DropDown({
    super.key,
    this.controller,
    this.hintText,
    this.height,
    this.width,
    this.backgroundColor,
    this.options = const <String>[],
    required this.onSelect,
    this.borderRadius = 8,
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
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FusionAppText(
                text: widget.hintText ?? 'Select',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          const VerticalDivider(color: Colors.black12, thickness: 1, width: 1),
          Theme(
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
              color: const Color(0xFFF5F5F5),
              shadowColor: Colors.transparent,
              position: PopupMenuPosition.under,
              tooltip: '',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
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
                              text: "No scenes saved",
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
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
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
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
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
