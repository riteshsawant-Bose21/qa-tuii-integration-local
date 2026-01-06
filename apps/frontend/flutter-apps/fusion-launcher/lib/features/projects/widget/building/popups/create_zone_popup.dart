import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';
import 'package:fusion_lib/models/project_entities/zone_functions.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      content: const NewWidget(),
      child: child,
    );
  }
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsGeometry.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // container 20 x 20
                  Row(
                    children: <Widget>[
                      Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FusionAppText(
                        text: "Zone Name",
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SizedBox(
                  //   height: 200,
                  //   child: FusionColorPicker(
                  //     initialColor: context.colorScheme.primaryColor,
                  //     onChanged: (Color value) {
                  //       //
                  //     },
                  //   ),
                  // ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: "Function",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: BuildingPageDronDown<ZoneFunctionsType>(
                          // value: selectedArea,
                          items: ZoneFunctionsType.values,
                          labelBuilder: (ZoneFunctionsType option) {
                            return FusionAppText(
                              text: option.displayName,
                              maxLine: 1,
                              style: Theme.of(context).textTheme.labelMedium,
                            );
                          },
                          hintText: "Select function type",
                          onSelect: (ZoneFunctionsType newValue) {
                            // addSourceViewModel.setListeningArea(newValue.id);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FusionAppText(
                          text: "Listening Areas",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: MultiSectionMultiSelectDropDown<String>(
                          hintText: 'Select speakers',
                          values: <String>{},
                          sections: <DropdownSection<String>>[
                            const DropdownSection<String>(
                              title: 'Analog',
                              items: <String>['Mic 1', 'Mic 2'],
                            ),
                            const DropdownSection<String>(
                              title: 'Digital',
                              items: <String>['HDMI', 'USB'],
                            ),
                          ],
                          onChanged: (Set<String> values) {
                            // setState(() => selectedValues = values);
                          },
                          labelBuilder: (String item, bool isSelected) {
                            return Text(
                              item,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: <Widget>[
                      Icon(
                        LucideIcons.plus200,
                        size: 16,
                        color: context.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FusionAppText(
                          text: "Add Listening Areas",
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
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
          ),
        ],
      ),
    );
  }
}
