// part of '../create_zone_popup.dart';
//
// class _CreateNewListeningAreaWidget extends StatefulWidget {
//   final ValueChanged<ListeningArea> onListeningAreaCreated;
//
//   const _CreateNewListeningAreaWidget({required this.onListeningAreaCreated});
//
//   @override
//   State<_CreateNewListeningAreaWidget> createState() => __CreateNewListeningAreaWidgetState();
// }
//
// class __CreateNewListeningAreaWidgetState extends State<_CreateNewListeningAreaWidget> {
//   final TextEditingController listeningAreaNameController = TextEditingController();
//   bool _isExpanded = false;
//   FloorModel? _selectedFloor;
//
//   final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
//
//   void _addNewLocationToFloor() {
//     if (listeningAreaNameController.text.trim().isEmpty || _selectedFloor == null) {
//       FusionToast.error(context, message: "Please enter location name and select a floor");
//       return;
//     }
//
//     final String floorId = _selectedFloor!.id;
//     final String locationName = listeningAreaNameController.text.trim();
//
//     final ListeningArea newListeningArea = ListeningArea(
//       name: locationName,
//       vertices: <FusionCanvasPoint>[],
//       isDrawn: false,
//     );
//
//     serviceLocator<ProjectViewModel>().addListeningArea(area: newListeningArea, floorId: floorId);
//     FusionToast.success(context, message: "Listening area '${newListeningArea.name}' created");
//     widget.onListeningAreaCreated(newListeningArea);
//
//     // clear inputs
//     listeningAreaNameController.clear();
//     _selectedFloor = null;
//     setState(() => _isExpanded = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         /// Header
//         GestureDetector(
//           onTap: () {
//             setState(() {
//               _isExpanded = !_isExpanded;
//             });
//           },
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: <Widget>[
//                 Expanded(
//                   child: FusionAppText(
//                     text: "Create new location",
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 SemanticHelper.toggle(
//                   testId: SemanticHelper.createTestId(SemanticTypes.toggle, "create_new_listening_area_toggle"),
//                   value: _isExpanded,
//                   child: Icon(
//                     _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                     size: 20,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//
//         /// Expanded form
//         if (_isExpanded) ...<Widget>[
//           Padding(
//             padding: const EdgeInsets.all(12.0).copyWith(top: 0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 /// Floor label
//                 FusionAppText(
//                   text: "Floor",
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//
//                 /// Floor dropdown
//                 BuildingPageDropDown<FloorModel>(
//                   value: _selectedFloor,
//                   items: serviceLocator<ProjectViewModel>().getAllFloors(),
//                   onSelect: (FloorModel selectedValue) {
//                     setState(() {
//                       _selectedFloor = selectedValue;
//                     });
//                   },
//                   labelBuilder: (FloorModel option) {
//                     return FusionAppText(
//                       text: option.name,
//                       style: Theme.of(context).textTheme.bodySmall,
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// Location Name
//                 FusionAppText(
//                   text: "Location Name",
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//
//                 SemanticHelper.formControl(
//                   testId: SemanticHelper.createTestId(SemanticTypes.textInput, "create_new_listening_area_input"),
//                   child: PropertyTextField(
//                     controller: listeningAreaNameController,
//                     hintText: 'Enter location name',
//                     contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//
//                 /// Add Button
//                 Align(
//                   alignment: Alignment.centerRight,
//
//                   child: FusionButton(
//                     accessLabel: 'create_new_listening_area_add_button',
//                     height: 28,
//                     width: 60,
//                     label: "Add",
//                     accessIdentifier: "create_new_listening_area_add_button",
//                     activeBackgroundColor: context.colorScheme.primaryColor,
//                     textStyle: context.textTheme.labelMedium?.copyWith(color: Colors.white),
//                     onTap: _addNewLocationToFloor,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }
// ─────────────────────────────────────────────────────────────
// Reusable UI Components
//
// Components extracted from create_zone_popup, create_subzone_widget,
// and zone_listening_area_section.
//
// Index:
//   1. FusionSectionLabel       — label text above any field
//   2. FusionLabeledField       — label + any child widget
//   3. FusionBorderedTextField  — no-border text input inside a rounded card
//   4. FusionHoverTextButton    — text that shifts colour on hover
//   5. FusionIconTextButton     — icon + text row button (e.g. "+ Add …")
//   6. FusionColorDot           — coloured square dot with edit-icon on hover
//   7. FusionDropdown<T>        — generic trigger + expandable item list
//   8. FusionColoredNameField   — colour dot + name input in one row
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// 1. FusionSectionLabel
//
// Standard label text rendered above a field.
//
// Usage:
//   FusionSectionLabel(label: 'Zone Name', semanticId: 'zone_name')
// ─────────────────────────────────────────────────────────────

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../../projects/widget/building/side_panel_widgets/schematic_properties.dart';

// ─────────────────────────────────────────────────────────────
// 2. FusionLabeledField
//
// Wraps any child with an optional label above and consistent spacing.
//
// Usage:
//   FusionLabeledField(
//     label: 'Floor Name',
//     semanticId: 'floor_name',
//     child: FusionBorderedTextField(...),
//   )
// ─────────────────────────────────────────────────────────────

class FusionLabeledField extends StatelessWidget {
  const FusionLabeledField({
    super.key,
    required this.child,
    required this.semanticId,
    this.label,
    this.spacing = 6,
  });

  final Widget child;
  final String semanticId;

  /// If null, no label is rendered.
  final String? label;

  /// Gap between label and child.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (label == null) return child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FusionAppText(
          semanticId: '${semanticId}_label',
          text: label!,
          style: Theme.of(context).textTheme.l1Medium.withColor(context.colorScheme.textPrimary),
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. FusionBorderedTextField
//
// Rounded bordered container holding a FusionTextField with
// no internal borders, hover background, and zero padding.
// Drop-in replacement for the repeated bordered-input pattern.
//
// Usage:
//   FusionBorderedTextField(
//     controller: _ctrl,
//     hintText: 'Enter zone name',
//     semanticId: 'zone_name',
//     onChanged: (v) => ...,
//   )
// ─────────────────────────────────────────────────────────────

class FusionBorderedTextField extends StatefulWidget {
  const FusionBorderedTextField({
    super.key,
    required this.controller,
    required this.semanticId,
    this.hintText = 'Enter value',
    this.maxLength,
    this.onChanged,
    this.contentPadding = const EdgeInsets.all(16),
    this.leading,
  });

  final TextEditingController controller;
  final String semanticId;
  final String hintText;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry contentPadding;

  /// Optional widget placed at the start of the row (e.g. a FusionColorDot).
  final Widget? leading;

  @override
  State<FusionBorderedTextField> createState() => _FusionBorderedTextFieldState();
}

class _FusionBorderedTextFieldState extends State<FusionBorderedTextField> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.formControl(
      testId: SemanticHelper.createTestId(SemanticTypes.textInput, widget.semanticId),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
            color: _hovering ? context.colorScheme.elevation2 : Colors.transparent,
          ),
          padding: widget.contentPadding,
          child: Row(
            children: <Widget>[
              if (widget.leading != null) ...<Widget>[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FusionTextField(
                  maxLength: widget.maxLength ?? 20,
                  semanticFieldId: '${widget.semanticId}_input',
                  controller: widget.controller,
                  hintText: widget.hintText,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPlaceholder),
                    labelStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPrimary),
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 4. FusionHoverTextButton
//
// A plain-text tap target that transitions between two colours
// on hover. Replaces the repeated MouseRegion + GestureDetector
// + FusionAppText pattern.
//
// Usage:
//   FusionHoverTextButton(
//     label: 'Cancel',
//     semanticId: 'subzone_cancel',
//     onTap: _exitSetupMode,
//   )
// ─────────────────────────────────────────────────────────────

class FusionHoverTextButton extends StatefulWidget {
  const FusionHoverTextButton({
    super.key,
    required this.label,
    required this.semanticId,
    required this.onTap,
    this.style,
    this.hoverColor,
  });

  final String label;
  final String semanticId;
  final VoidCallback onTap;

  /// Base text style. Defaults to l1SemiBold in textPrimary.
  final TextStyle? style;

  /// Colour when hovered. Defaults to colorScheme.elevation6.
  final Color? hoverColor;

  @override
  State<FusionHoverTextButton> createState() => _FusionHoverTextButtonState();
}

class _FusionHoverTextButtonState extends State<FusionHoverTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = widget.style ?? context.textTheme.l1SemiBold.copyWith(color: context.colorScheme.textPrimary);

    final Color hoverColor = widget.hoverColor ?? context.colorScheme.elevation6;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, widget.semanticId),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: FusionAppText(
            text: widget.label,
            style: base.copyWith(color: _hovered ? hoverColor : base.color),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 5. FusionIconTextButton
//
// A leading icon + label row used for "+ Add …" type actions.
//
// Usage:
//   FusionIconTextButton(
//     icon: LucideIcons.plus,
//     label: 'Add SubZones',
//     semanticId: 'add_subzones',
//     onTap: _enterSetupMode,
//   )
// ─────────────────────────────────────────────────────────────

class FusionIconTextButton extends StatefulWidget {
  const FusionIconTextButton({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticId,
    required this.onTap,
    this.iconSize = 14,
    this.spacing = 5,
    this.style,
    this.iconColor,
    this.hoverColor,
  });

  final IconData icon;
  final String label;
  final String semanticId;
  final VoidCallback onTap;
  final double iconSize;
  final double spacing;

  /// Base text style. Defaults to bodySmall in onSurface.
  final TextStyle? style;

  /// Base icon colour. Defaults to colorScheme.primaryWhite.
  final Color? iconColor;

  /// Hover colour applied to both icon and text.
  final Color? hoverColor;

  @override
  State<FusionIconTextButton> createState() => _FusionIconTextButtonState();
}

class _FusionIconTextButtonState extends State<FusionIconTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color baseIconColor = widget.iconColor ?? context.colorScheme.primaryWhite;
    final Color baseTextColor = (widget.style?.color) ?? context.colorScheme.onSurface;
    final Color hover = widget.hoverColor ?? context.colorScheme.elevation6;

    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, widget.semanticId),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: widget.iconSize,
                color: _hovered ? hover : baseIconColor,
              ),
              SizedBox(width: widget.spacing),
              FusionAppText(
                text: widget.label,
                style: (widget.style ?? context.textTheme.bodySmall?.copyWith(color: baseTextColor))?.copyWith(color: _hovered ? hover : baseTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 6. FusionColorDot
//
// A small rounded square filled with [color] that shows an
// edit pencil on hover. Tapping toggles a colour picker or
// calls [onTap].
//
// Usage:
//   FusionColorDot(
//     hexColor: state.zoneColor,
//     semanticId: 'zone_color',
//     onTap: () => setState(() => _showColorGrid = !_showColorGrid),
//   )
// ─────────────────────────────────────────────────────────────

class FusionColorDot extends StatefulWidget {
  const FusionColorDot({
    super.key,
    required this.hexColor,
    required this.semanticId,
    required this.onTap,
    this.size = 16,
  });

  final String hexColor;
  final String semanticId;
  final VoidCallback onTap;
  final double size;

  @override
  State<FusionColorDot> createState() => _FusionColorDotState();
}

class _FusionColorDotState extends State<FusionColorDot> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      value: widget.hexColor,
      testId: SemanticHelper.createTestId(SemanticTypes.container, '${widget.semanticId}_color_dot'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.hexColor.isNotEmpty ? hexToColor(widget.hexColor) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: context.colorScheme.zone1Stroke, width: 0.75),
            ),
            child: _hovering ? FusionIcon.icon(Icons.edit, size: widget.size * 0.625, color: Colors.white) : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 7. FusionDropdown<T>
//
// Generic trigger-button + collapsible item list.
// Covers both the listening-area selector and the floor picker.
//
// Usage:
//   FusionDropdown<FloorModel>(
//     semanticId: 'floor_picker',
//     selectedLabel: _selectedFloor?.name ?? 'Select Floor',
//     isSelected: _selectedFloor != null,
//     items: floors,
//     itemBuilder: (context, floor) => Text(floor.name),
//     onItemTap: (floor) => setState(() { _selectedFloor = floor; }),
//     headerChild: _buildAddNewFloorRow(),   // optional pinned top row
//   )
// ─────────────────────────────────────────────────────────────

class FusionDropdown<T> extends StatefulWidget {
  const FusionDropdown({
    super.key,
    required this.semanticId,
    required this.selectedLabel,
    required this.items,
    required this.itemBuilder,
    required this.onItemTap,
    this.isSelected = false,
    this.triggerHeight = 40,
    this.headerChild,
    this.isItemSelected,
  });

  final String semanticId;

  /// Text shown in the trigger button.
  final String selectedLabel;

  /// Whether something is currently selected (affects label opacity).
  final bool isSelected;

  final List<T> items;

  /// Builds the row content for each item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Called when an item row is tapped.
  final void Function(T item) onItemTap;

  /// Optional widget pinned at the top of the dropdown body (e.g. "+ Add New").
  final Widget? headerChild;

  /// Highlight the row when true (e.g. floor already selected).
  final bool Function(T item)? isItemSelected;

  final double triggerHeight;

  @override
  State<FusionDropdown<T>> createState() => _FusionDropdownState<T>();
}

class _FusionDropdownState<T> extends State<FusionDropdown<T>> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── Trigger ──────────────────────────────────────────
        SemanticHelper.button(
          testId: SemanticHelper.createTestId(SemanticTypes.button, '${widget.semanticId}_trigger'),
          child: GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              height: widget.triggerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colorScheme.strokeLight, width: 1),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: widget.selectedLabel,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: widget.isSelected ? context.colorScheme.onSurface : context.colorScheme.onSurface.withAlpha(155),
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: context.colorScheme.iconDefault,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Dropdown body ─────────────────────────────────────
        if (_isOpen) ...<Widget>[
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colorScheme.strokeLight, width: 1),
              color: context.colorScheme.elevation2,
            ),
            child: Column(
              children: <Widget>[
                // Optional pinned header row (e.g. "+ Add New Floor")
                if (widget.headerChild != null) ...<Widget>[
                  widget.headerChild!,
                  Divider(height: 0, thickness: 0.5, color: context.colorScheme.strokeLight),
                ],

                // Item rows
                ...widget.items.map((T item) {
                  final bool selected = widget.isItemSelected?.call(item) ?? false;
                  return GestureDetector(
                    onTap: () {
                      widget.onItemTap(item);
                      setState(() => _isOpen = false);
                    },
                    child: SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, '${widget.semanticId}_item_$item'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: selected ? context.colorScheme.elevation3 : Colors.transparent,
                        child: widget.itemBuilder(context, item),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 8. FusionColoredNameField
//
// Color dot + text input in a single hover-bordered row,
// with an optional collapsible color-grid below.
//
// Usage:
//   FusionColoredNameField(
//     name: state.zoneName,
//     hexColor: state.zoneColor,
//     availableColors: Zone.zoneColors,
//     label: 'Zone Name',
//     hintText: 'Enter zone name',
//     semanticId: 'zone',
//     onNameChanged: vm.setZoneName,
//     onColorChanged: vm.setZoneColor,
//   )
// ─────────────────────────────────────────────────────────────

class FusionColoredNameField extends StatefulWidget {
  const FusionColoredNameField({
    super.key,
    required this.name,
    required this.hexColor,
    required this.availableColors,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.semanticId,
    this.label,
    this.hintText = 'Enter name',
    this.maxLength = 30,
  });

  final String name;
  final String hexColor;
  final List<String> availableColors;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onColorChanged;
  final String semanticId;
  final String? label;
  final String hintText;
  final int maxLength;

  @override
  State<FusionColoredNameField> createState() => _FusionColoredNameFieldState();
}

class _FusionColoredNameFieldState extends State<FusionColoredNameField> {
  bool _showColorGrid = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);

    // Assign a random color on first render if none is set.
    if (widget.hexColor.isEmpty && widget.availableColors.isNotEmpty) {
      final String randomColor = widget.availableColors[math.Random().nextInt(widget.availableColors.length)];
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onColorChanged(randomColor));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, '${widget.semanticId}_name_field_section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.label != null) ...<Widget>[
            FusionAppText(text: widget.label!, semanticId: '${widget.semanticId}_name_field_label'),
            const SizedBox(height: 8),
          ],

          // ── Name row with color dot ───────────────────────
          FusionBorderedTextField(
            controller: _controller,
            semanticId: '${widget.semanticId}_name_field',
            hintText: widget.hintText,
            maxLength: widget.maxLength,
            onChanged: widget.onNameChanged,
            leading: FusionColorDot(
              hexColor: widget.hexColor,
              semanticId: widget.semanticId,
              onTap: () => setState(() => _showColorGrid = !_showColorGrid),
            ),
          ),

          // ── Collapsible color grid ────────────────────────
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, '${widget.semanticId}_color_grid_section'),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              curve: Curves.easeOut,
              child: SizedBox(
                width: double.infinity,
                child:
                    _showColorGrid
                        ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colorScheme.elevation2,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: context.colorScheme.elevation4, width: 1),
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 16,
                                crossAxisSpacing: 7,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: widget.availableColors.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String hex = widget.availableColors[index];
                                final bool isSelected = widget.hexColor == hex;
                                return GestureDetector(
                                  onTap: () {
                                    widget.onColorChanged(hex);
                                    setState(() => _showColorGrid = false);
                                  },
                                  child: SemanticHelper.container(
                                    testId: SemanticHelper.createTestId(SemanticTypes.container, '${widget.semanticId}_color_option_$index'),
                                    isChecked: isSelected,
                                    value: hex,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: hexToColor(hex),
                                        borderRadius: BorderRadius.circular(3),
                                        border: isSelected ? Border.all(color: context.colorScheme.primaryWhite, width: 2) : null,
                                      ),
                                      child: isSelected ? FusionIcon.icon(Icons.check, color: Colors.white, size: 10) : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
