import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/assets/asset_svg.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SectionHeaderWithActions extends StatefulWidget {
  final String sectionTitle;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchTextChanged;

  const SectionHeaderWithActions({
    super.key,
    required this.sectionTitle,
    required this.searchController,
    required this.onSearchTextChanged,
  });

  @override
  State<SectionHeaderWithActions> createState() => _SectionHeaderWithActionsState();
}

class _SectionHeaderWithActionsState extends State<SectionHeaderWithActions> {
  final FocusNode _searchFocusNode = FocusNode();
  ValueNotifier<bool> showSearchBarNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder border = OutlineInputBorder(borderRadius: BorderRadius.circular(FusionSizes.borderRadius16), borderSide: BorderSide.none);

    return SizedBox(
      height: 30,
      child: ValueListenableBuilder<bool>(
        valueListenable: showSearchBarNotifier,
        builder: (BuildContext context, bool showSearchBar, Widget? child) {
          return Row(
            children: <Widget>[
              if (showSearchBar) ...<Widget>[
                Expanded(
                  child: TextFormField(
                    focusNode: _searchFocusNode,
                    controller: widget.searchController,
                    style: context.textTheme.labelSmall,
                    cursorColor: context.colorScheme.onSurface,
                    cursorWidth: 1,
                    cursorHeight: 14,
                    onChanged: widget.onSearchTextChanged,
                    onTapOutside: (PointerDownEvent event) {
                      if (widget.searchController.text.trim().isEmpty) {
                        showSearchBarNotifier.value = !showSearchBar;
                        if (showSearchBar) {
                          widget.searchController.clear();
                          _searchFocusNode.unfocus();
                        }
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      isDense: true,
                      fillColor: context.colorScheme.elevation2,
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      hintText: "Search",
                      hintStyle: context.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.textBody,
                        fontSize: 12,
                      ),
                      hoverColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    ),
                  ),
                ),
              ] else ...<Widget>[
                FusionSvgIcon(
                  icon: AssetSvg.expandUp,
                  size: FusionSizes.iconSize16,
                  color: context.colorScheme.iconWhite,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FusionAppText(
                    text: widget.sectionTitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: FusionSizes.fontSize12,
                      color: context.colorScheme.textBody,
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showSearchBarNotifier.value = !showSearchBar;
                  if (showSearchBar) {
                    widget.onSearchTextChanged('');
                    widget.searchController.clear();
                    _searchFocusNode.unfocus();
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (Duration timeStamp) {
                        FocusScope.of(context).requestFocus(_searchFocusNode);
                      },
                    );
                  }
                },
                child: Icon(
                  key: ValueKey<bool>(showSearchBar),
                  showSearchBar ? LucideIcons.x200 : LucideIcons.search200,
                  size: FusionSizes.iconSize16,
                  color: context.colorScheme.primaryWhite,
                ),
              ),

              if (!showSearchBar) ...<Widget>[
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.plus200,
                  size: FusionSizes.iconSize16,
                  color: context.colorScheme.primaryWhite,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
