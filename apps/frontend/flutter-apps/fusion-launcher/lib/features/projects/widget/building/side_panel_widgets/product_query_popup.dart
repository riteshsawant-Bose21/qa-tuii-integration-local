import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/authentication/launcher_sign_in_page.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_text_button.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
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
                FusionAppText(
                  text: "SPEAKERS",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                  ),
                ),
                PopupMenuButton<String>(
                  color: Colors.transparent,
                  shadowColor: Colors.transparent,
                  // position: PopupMenuPosition.under,
                  tooltip: 'Add sources',
                  padding: EdgeInsets.zero,
                  menuPadding: EdgeInsets.zero,
                  clipBehavior: Clip.none,
                  offset: const Offset(45, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(
                      LucideIcons.plus200,
                      size: 14,
                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                    ),
                  ),
                  // onSelected: (String value) {},
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        padding: EdgeInsets.zero,

                        child: Theme(data: ThemeData.dark(), child: const _PopUpWidget()),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const NeumorphicDarkTextField(
            
          ),
          const SizedBox(height: 10),
          // BorderedTextfield(
          //   focusNode: listeningAreaNameFocusNode,
          //   hintText: "Enter listening area name",
          //   controller: listeningAreaNameController,
          //   borderRadius: 4,
          //   contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          //   validator: (String? value) {
          //     final String trimmedFloorName = value?.trim() ?? '';
          //     if (trimmedFloorName.isEmpty) return 'Required';
          //     return null;
          //   },
          //   onSubmitted: onSave,
          // ),
          const SizedBox(height: 18),
          FusionAppText(
            text: "Select Floor",
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FusionTextButton(
                height: 28,
                width: 70,
                borderRadius: 4,
                label: "Cancel",
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(),
                onTap: () {
                  // listeningAreaNameController.clear();
                  // Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 8),
              FusionTextButton(
                height: 28,
                width: 90,
                borderRadius: 4,
                backgroundColor: context.colorScheme.primary,
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(),
                label: "Save",
                onTap: () {
                  // final String trimmedListeningAreaName = listeningAreaNameController.text.trim();
                  // onSave(trimmedListeningAreaName);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
