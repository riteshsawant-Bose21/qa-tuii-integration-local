import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/parts/properties_and_filter_section.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'color_picker.dart';

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

class CreateZonePopup extends StatelessWidget {
  final Widget child;
  const CreateZonePopup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FusionArrowPopup(
      blurAmount: 1,
      backgroundColor: const Color(0xFF292826),
      content: Container(
        width: 350,
        height: 500,
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
                      text: 'CREATE ZONE',
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
            Padding(
              padding: const EdgeInsetsGeometry.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionColorPicker(
                    initialColor: context.colorScheme.primaryColor,
                    onChanged: (Color value) {
                      //
                    },
                  ),

                  FusionRadio<SourceOption>(
                    selected: SourceOption.singleSource,
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
                    onChanged: (SourceOption value) {},
                  ),
                  const SizedBox(height: 20),
                  BuildRowPropertyWidget(
                    label: "Type",
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
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}

class FusionColorPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onChanged;

  const FusionColorPicker({
    super.key,
    required this.initialColor,
    required this.onChanged,
  });

  @override
  State<FusionColorPicker> createState() => _FusionColorPickerState();
}

class _FusionColorPickerState extends State<FusionColorPicker> {
  @override
  Widget build(BuildContext context) {
    return ColorPicker(
      pickerColor: widget.initialColor,
      onColorChanged: widget.onChanged,
      colorPickerWidth: 0,
      paletteType: PaletteType.hsv,
    );
  }
}
