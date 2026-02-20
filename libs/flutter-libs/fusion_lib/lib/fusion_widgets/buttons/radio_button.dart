import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A customizable selection widget for the Fusion design system.
///
/// The [RadioButton] supports multiple selection variants including
/// checkbox, radio button, radio box, and radio option styles.
///
/// It provides built-in support for:
/// - Two-state and three-state selection
/// - Disabled and enabled states
/// - Optional labels and prefix icons
/// - Theme-aware colors
/// - Custom shapes for radio buttons
///
/// The widget automatically manages state transitions based on the
/// selected [FusionSelectionVariant].
///
/// ### Supported Variants
/// - [FusionSelectionVariant.checkbox] → Standard checkbox (3-state)
/// - [FusionSelectionVariant.radio] → Circular radio button (3-state)
/// - [FusionSelectionVariant.radioBox] → Radio with container and label (2-state)
/// - [FusionSelectionVariant.radioOption] → Option-style radio with icons (2-state)
///
/// ### Selection States
/// - [FusionSelectionState.unchecked]
/// - [FusionSelectionState.checked]
/// - [FusionSelectionState.partial] (Only for 3-state variants)
///
/// ### Features
/// - Automatic state handling
/// - Two-state and three-state logic
/// - Disabled interaction support
/// - Optional prefix icons
/// - Customizable shape
/// - Adaptive colors from theme
///
/// ### Example: Checkbox
/// ```dart
/// RadioButton(
///   variant: FusionSelectionVariant.checkbox,
///   label: 'Accept Terms',
///   state: FusionSelectionState.unchecked,
///   onTap: () {
///     print('Checkbox tapped');
///   },
/// )
/// ```
///
/// ### Example: Radio Option
/// ```dart
/// RadioButton(
///   variant: FusionSelectionVariant.radioOption,
///   label: 'Enable Feature',
///   iconPrifix: true,
///   state: FusionSelectionState.checked,
///   onTap: () {},
/// )
/// ```
///
/// ### Example: Disabled Radio Box
/// ```dart
/// RadioButton(
///   variant: FusionSelectionVariant.radioBox,
///   label: 'Premium Plan',
///   disabled: true,
///   state: FusionSelectionState.unchecked,
/// )
/// ```
///
/// ### Notes
/// - Two-state variants automatically ignore the `partial` state.
/// - State is managed internally but can be controlled externally.
/// - Uses Fusion color scheme for consistent theming.
enum FusionSelectionVariant {
  checkbox,
  radio,
  radioBox,
  radioOption,
}

enum FusionSelectionState {
  unchecked,
  checked,
  partial,
}

class RadioButton extends StatefulWidget {
  final FusionSelectionVariant variant;
  FusionSelectionState state;
  final bool disabled;
  final String? label;
  final BoxShape shape;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool iconPrifix;
  final String? semanticId;

  RadioButton({
    super.key,
    this.semanticId,
    this.width = 16,
    this.height = 16,
    this.iconPrifix = false,
    required this.variant,
    this.state = FusionSelectionState.unchecked,
    this.disabled = false,
    this.label,
    this.shape = BoxShape.circle,
    this.onTap,
  });

  @override
  State<RadioButton> createState() => _RadioButtonState();
}

class _RadioButtonState extends State<RadioButton> {
  bool get _isChecked => widget.state == FusionSelectionState.checked;
  bool get _isPartial => widget.state == FusionSelectionState.partial;
  bool get _isEnabled => !widget.disabled;
  bool? toSemanticsChecked() {
    switch (widget.state) {
      case FusionSelectionState.checked:
        return true;
      case FusionSelectionState.unchecked:
        return false;
      case FusionSelectionState.partial:
        return null; // important
    }
  }

  // 🔹 Two-state variants
  bool get _isTwoStateVariant =>
      widget.variant == FusionSelectionVariant.radioBox ||
      widget.variant == FusionSelectionVariant.radioOption;

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (_isTwoStateVariant && widget.state == FusionSelectionState.partial) {
      widget.state = FusionSelectionState.unchecked;
    }

    return SemanticHelper.button(
      isActive: _isEnabled,
      selected: _isChecked,
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "radio_button${widget.semanticId}",
      ),
      label: widget.label,
      state: toSemanticsChecked(),
      child: GestureDetector(
        onTap: _isEnabled
            ? () {
                setState(() {
                  widget.state = _nextState(widget.state);
                });

                widget.onTap?.call();
              }
            : null,
        child: Opacity(
          opacity: _isEnabled ? 1 : 0.4,
          child: _buildByVariant(),
        ),
      ),
    );
  }

  // ================= STATE LOGIC =================

  FusionSelectionState _nextState(FusionSelectionState current) {
    if (_isTwoStateVariant) {
      return current == FusionSelectionState.checked
          ? FusionSelectionState.unchecked
          : FusionSelectionState.checked;
    }
    switch (current) {
      case FusionSelectionState.unchecked:
        return FusionSelectionState.checked;
      case FusionSelectionState.checked:
        return FusionSelectionState.partial;
      case FusionSelectionState.partial:
        return FusionSelectionState.unchecked;
    }
  }

  // ================= SWITCH =================

  Widget _buildByVariant() {
    switch (widget.variant) {
      case FusionSelectionVariant.checkbox:
        return _buildCheckbox();

      case FusionSelectionVariant.radio:
        return _buildRadio();

      case FusionSelectionVariant.radioBox:
        return _buildRadioBox();

      case FusionSelectionVariant.radioOption:
        return _buildRadioOption();
    }
  }

  // ================= COLORS =================

  Color get _borderColor {
    if (widget.disabled) return context.colorScheme.elevation1;
    if (_isChecked || _isPartial) return context.colorScheme.white;
    return Colors.grey;
  }

  Color get _fillColor {
    if (widget.disabled) return context.colorScheme.elevation1;
    if (_isChecked || _isPartial) return context.colorScheme.white;
    return Colors.transparent;
  }

  Color get _iconColor => Colors.black;

  // ================= CHECKBOX =================

  Widget _buildCheckbox() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _borderColor,
            width: 1.5,
          ),
          color: _fillColor,
        ),
        child: Center(child: _buildCheckboxIcon()),
      ),
    );
  }

  Widget? _buildCheckboxIcon() {
    if (_isChecked) {
      return Icon(Icons.check, size: 16, color: _iconColor);
    }

    if (_isPartial) {
      return Icon(Icons.remove, size: 16, color: _iconColor);
    }

    return null;
  }

  // ================= RADIO =================

  Widget _buildRadio() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          shape: widget.shape,
          border: Border.all(
            color: widget.variant == FusionSelectionVariant.radioOption
                ? widget.state == FusionSelectionState.checked
                      ? context.colorScheme.green
                      : _borderColor
                : _borderColor,
            width: 1.5,
          ),
          color: _isPartial
              ? widget.variant == FusionSelectionVariant.radioOption
                    ? context.colorScheme.green
                    : context.colorScheme.white
              : Colors.transparent,
        ),
        child: Center(child: _buildRadioInner()),
      ),
    );
  }

  Widget? _buildRadioInner() {
    if (_isChecked) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: widget.variant == FusionSelectionVariant.radioOption
              ? context.colorScheme.green
              : context.colorScheme.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            size: 12,
            widget.variant == FusionSelectionVariant.radio
                ? Icons.circle
                : Icons.check,
            fontWeight: FontWeight.bold,
            color: widget.variant == FusionSelectionVariant.radio
                ? context.colorScheme.iconWhite
                : context.colorScheme.black,
          ),
        ),
      );
    }

    // Partial only for 3-state
    if (_isPartial && !_isTwoStateVariant) {
      return Icon(
        Icons.check,
        size: 16,
        color: _iconColor,
      );
    }

    return null;
  }

  // ================= RADIO BOX =================

  Widget _buildRadioBox() {
    final active = _isChecked;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: widget.disabled
            ? context.colorScheme.elevation1
            : active
            ? context.colorScheme.elevation2
            : context.colorScheme.primaryBlack,
      ),
      child: Center(
        child: Row(
          children: [
            _buildRadio(),

            const SizedBox(width: 12),

            Text(
              widget.label ?? '',
              style: _labelStyle(active),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RADIO OPTION =================

  Widget _buildRadioOption() {
    final active = _isChecked;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: widget.disabled
            ? context.colorScheme.elevation1
            : active
            ? context.colorScheme.elevation2
            : context.colorScheme.elevation1,
        // border: Border.all(
        //   color: widget.disabled
        //       ? Colors.grey.shade700
        //       : active
        //       ? Colors.white
        //       : Colors.transparent,
        //   width: 1.2,
        // ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 2,
        children: [
          Row(
            children: [
              if (widget.iconPrifix) ...[
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 20,
                  color: active
                      ? context.colorScheme.iconWhite
                      : context.colorScheme.iconDisabled,
                ),
              ] else ...[
                _buildRadio(),
              ],
              SizedBox(
                width: 10,
              ),

              Text(
                widget.label ?? '',
                style: _labelStyle(active),
              ),
              SizedBox(
                width: 200,
              ),
            ],
          ),

          if (widget.iconPrifix) ...[
            _buildRadio(),
          ] else ...[
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: active
                  ? context.colorScheme.iconWhite
                  : context.colorScheme.iconDisabled,
            ),
          ],
        ],
      ),
    );
  }

  // ================= TEXT STYLE =================

  TextStyle _labelStyle(bool active) {
    return TextStyle(
      fontSize: 14,
      color: widget.disabled
          ? context.colorScheme.textDisabled
          : context.colorScheme.white,
    );
  }
}
