import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// ---------------- FIELD STATE ----------------

enum FusionFieldState {
  defaultState,
  focused,
  filled,
  error,
  errorFocused,
  blocked,
  blockedFilled,
}

/// ---------------- UI VARIANT ----------------

enum FusionFieldVariant {
  outline,
  neumorphic,
}

/// ---------------- WIDGET ----------------

class CustomTextField extends StatefulWidget {
  final String? label;
  final String hint;
  final TextEditingController controller;

  final bool enabled;
  final bool hasErrorText;
  final String errorText;

  final bool isDropdown;
  final List<String>? dropdownItems;
  final ValueChanged<String>? onItemSelected;

  final bool info;
  final VoidCallback? infoTap;

  final bool showPrefixIcon;
  final IconData? prefixIcon;

  final bool showSuffixIcon;
  final IconData? suffixIcon;

  final String successText;
  final String helperText;
  final bool hasSuccessText;
  final bool hasHelperText;

  final bool button;
  final VoidCallback? buttonTap;
  final String buttonText;

  final bool showLabel;
  final bool showCountryCode;

  final VoidCallback? onTap;

  final TextInputType? inputType;

  final FusionFieldState? fieldState;
  final FusionFieldVariant variant;
  final bool showRupee;
  final String semanticId;

  const CustomTextField({
    super.key,
    required this.semanticId,
    this.showRupee = false,
    this.label,
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.hasErrorText = false,
    this.errorText = '',
    this.isDropdown = false,
    this.dropdownItems,
    this.onItemSelected,
    this.info = false,
    this.infoTap,
    this.showPrefixIcon = false,
    this.prefixIcon,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.successText = '',
    this.helperText = '',
    this.hasSuccessText = false,
    this.hasHelperText = false,
    this.button = false,
    this.buttonTap,
    this.buttonText = "Submit",
    this.showLabel = true,
    this.showCountryCode = false,
    this.onTap,
    this.inputType,
    this.fieldState,
    this.variant = FusionFieldVariant.outline,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

/// ---------------- STATE ----------------

class _CustomTextFieldState extends State<CustomTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;

  double _fieldWidth = 0;
  double _fieldHeight = 0;

  final GlobalKey _fieldKey = GlobalKey();

  late FocusNode _focusNode;

  bool _isFocused = false;

  CountryCode _selectedCountry = CountryCode.fromDialCode('+91');

  // ---------------- INIT ----------------

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeDropdown();
      }

      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });

    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _removeDropdown();
    super.dispose();
  }

  // ---------------- SIZE CALC ----------------

  void _calculateSize() {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (box != null) {
      _fieldWidth = box.size.width;
      _fieldHeight = box.size.height;
    }
  }

  // ---------------- DROPDOWN ----------------

  void _toggleDropdown() {
    if (!widget.enabled) return;

    _calculateSize();

    if (_dropdownOverlay != null) {
      _removeDropdown();
      return;
    }

    if (widget.dropdownItems == null || widget.dropdownItems!.isEmpty) return;

    final overlay = Overlay.of(context);

    _dropdownOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier to close dropdown when tapping outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeDropdown,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // Dropdown content
            Positioned(
              left: _fieldKey.currentContext!.findRenderObject() != null
                  ? (_fieldKey.currentContext!.findRenderObject() as RenderBox)
                        .localToGlobal(Offset.zero)
                        .dx
                  : 0,
              top: _fieldKey.currentContext!.findRenderObject() != null
                  ? (_fieldKey.currentContext!.findRenderObject() as RenderBox)
                            .localToGlobal(Offset.zero)
                            .dy +
                        _fieldHeight +
                        2
                  : 0,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                child: Container(
                  width: _fieldWidth,
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.colorScheme.elevation3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.dropdownItems!.length,
                      itemBuilder: (context, index) {
                        final item = widget.dropdownItems![index];
                        return InkWell(
                          // onTap: () {
                          //   setState(() {
                          //
                          //   });
                          //   widget.onItemSelected?.call(item);
                          //   // _removeDropdown();
                          // },
                          onTap: () {
                            setState(() {
                              widget.controller.text = item;
                            });
                            _removeDropdown();
                          },
                          hoverColor: Colors.white.withOpacity(0.06),
                          splashColor: Colors.white.withOpacity(0.1),
                          child: Container(
                            height: 44,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                color: context.colorScheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_dropdownOverlay!);
  }

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  // Add this list at the top of your _CustomTextFieldState class

  String _selectedCountryCode = '+91';

  void _showCountryCodePicker() {
    if (!widget.enabled) return;

    _calculateSize();

    if (_dropdownOverlay != null) {
      _removeDropdown();
      return;
    }

    final overlay = Overlay.of(context);

    TextEditingController searchController = TextEditingController();

    _dropdownOverlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _removeDropdown,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, _fieldHeight + 2),
                  child: Material(
                    color: Colors.transparent,
                    child: StatefulBuilder(
                      builder: (context, setOverlayState) {
                        List<Map<String, String>> filteredCountries = countries
                            .where(
                              (country) =>
                                  country['name']!.toLowerCase().contains(
                                    searchController.text.toLowerCase(),
                                  ) ||
                                  country['code']!.contains(
                                    searchController.text,
                                  ),
                            )
                            .toList();

                        return Container(
                          width: _fieldWidth,
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: this.context.colorScheme.elevation3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Search field
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: searchController,
                                  onChanged: (value) {
                                    setOverlayState(() {});
                                  },
                                  style: TextStyle(
                                    color: this.context.colorScheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search country',
                                    hintStyle: TextStyle(
                                      color: this
                                          .context
                                          .colorScheme
                                          .textPlaceholder,
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: this
                                          .context
                                          .colorScheme
                                          .textPlaceholder,
                                      size: 20,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),

                              // Country list
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                  child: filteredCountries.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Text(
                                              'No country found',
                                              style: TextStyle(
                                                color: this
                                                    .context
                                                    .colorScheme
                                                    .textPlaceholder,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: filteredCountries.length,
                                          itemBuilder: (context, index) {
                                            final country =
                                                filteredCountries[index];
                                            final isSelected =
                                                _selectedCountryCode ==
                                                country['code'];

                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedCountryCode =
                                                      country['code']!;
                                                  _selectedCountry =
                                                      CountryCode(
                                                        name: country['name'],
                                                        dialCode:
                                                            country['code'],
                                                        code: country['iso'],
                                                      );
                                                });
                                                _removeDropdown();
                                              },
                                              hoverColor: Colors.white
                                                  .withOpacity(0.06),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? this
                                                            .context
                                                            .colorScheme
                                                            .elevation3
                                                            .withOpacity(0.3)
                                                      : Colors.transparent,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        country['name']!,
                                                        style: TextStyle(
                                                          color: this
                                                              .context
                                                              .colorScheme
                                                              .textPrimary,
                                                          fontSize: 14,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      country['code']!,
                                                      style: TextStyle(
                                                        color: this
                                                            .context
                                                            .colorScheme
                                                            .textPrimary,
                                                        fontSize: 14,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_dropdownOverlay!);
  }

  // ---------------- STATE ----------------

  FusionFieldState _getFieldState() {
    if (widget.fieldState != null) {
      return widget.fieldState!;
    }

    final hasText = widget.controller.text.isNotEmpty;

    if (!widget.enabled && hasText) {
      return FusionFieldState.blockedFilled;
    }

    if (!widget.enabled) {
      return FusionFieldState.blocked;
    }

    if (widget.hasErrorText && _isFocused) {
      return FusionFieldState.errorFocused;
    }

    if (widget.hasErrorText) {
      return FusionFieldState.error;
    }

    if (_isFocused) {
      return FusionFieldState.focused;
    }

    if (hasText) {
      return FusionFieldState.filled;
    }

    return FusionFieldState.defaultState;
  }

  // ---------------- COLORS ----------------

  Color _borderColor() {
    switch (_getFieldState()) {
      case FusionFieldState.focused:
        return context.colorScheme.textPrimary;

      case FusionFieldState.error:
      case FusionFieldState.errorFocused:
        return context.colorScheme.errorText;

      case FusionFieldState.blocked:
      case FusionFieldState.blockedFilled:
        return context.colorScheme.elevation3;

      default:
        return context.colorScheme.elevation3;
    }
  }

  Color _fillColor() {
    switch (_getFieldState()) {
      case FusionFieldState.blocked:
      case FusionFieldState.blockedFilled:
        return context.colorScheme.elevation1;

      default:
        return context.colorScheme.elevation1;
      // default:
      //   return Colors.transparent;
    }
  }

  // ---------------- DECORATION ----------------

  BoxDecoration _getDecoration() {
    if (widget.variant == FusionFieldVariant.neumorphic) {
      return BoxDecoration(
        color: _fillColor(),
        borderRadius: BorderRadius.circular(12),
        // boxShadow: widget.fieldState == FusionFieldState.focused
        //     ? [
        //         BoxShadow(
        //           color: context.colorScheme.shadowDark,
        //           blurRadius: 4,
        //           offset: const Offset(2, 2),
        //         ),
        //         BoxShadow(color: context.colorScheme.elevation1),
        //       ]
        //     : [
        //         BoxShadow(
        //           color: context.colorScheme.shadowDark,
        //           blurRadius: 1,
        //           offset: Offset(-2, -2),
        //           blurStyle: BlurStyle.inner,
        //         ),
        //         BoxShadow(
        //           color: context.colorScheme.shadowLight,
        //           blurRadius: 1,
        //           offset: Offset(2, 2),
        //           blurStyle: BlurStyle.inner,
        //         ),
        //         BoxShadow(
        //           color: context.colorScheme.elevation1,
        //           blurRadius: 4,
        //           blurStyle: BlurStyle.inner,
        //         ),
        //       ],
      );
    }

    return BoxDecoration(
      color: _fillColor(),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _borderColor(),
        width: 2,
      ),
    );
  }

  bool isFocused(FusionFieldState state) {
    return state == FusionFieldState.focused ||
        state == FusionFieldState.errorFocused;
  }

  String semanticsValue(FusionFieldState state) {
    switch (state) {
      case FusionFieldState.defaultState:
        return 'Empty';

      case FusionFieldState.focused:
        return 'Editing';

      case FusionFieldState.filled:
        return 'Filled';

      case FusionFieldState.error:
        return 'Error';

      case FusionFieldState.errorFocused:
        return 'Error, editing';

      case FusionFieldState.blocked:
        return 'Disabled';

      case FusionFieldState.blockedFilled:
        return 'Disabled, filled';
    }
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.textInput(
      testId: SemanticHelper.createTestId(
        SemanticTypes.textInput,
        "textfield_${widget.semanticId ?? ""}",
      ),
      enabled: widget.enabled,
      focused: isFocused(_getFieldState()),
      value: semanticsValue(_getFieldState()),
      live:
          _getFieldState() == FusionFieldState.error ||
          _getFieldState() == FusionFieldState.errorFocused,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LABEL
          if (widget.showLabel)
            Row(
              children: [
                FusionAppText(
                  text: widget.label ?? '',
                  style: TextStyle(
                    color: widget.hasErrorText
                        ? context.colorScheme.errorText
                        : widget.fieldState == FusionFieldState.blocked
                        ? context.colorScheme.textDisabled
                        : context.colorScheme.primaryWhite,
                    fontSize: 13,
                  ),
                ),
                SizedBox(
                  width: 2,
                ),
                if (widget.info) ...[
                  GestureDetector(
                    onTap: widget.infoTap,
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: widget.hasErrorText
                          ? context.colorScheme.errorText
                          : widget.fieldState == FusionFieldState.blocked
                          ? context.colorScheme.textDisabled
                          : context.colorScheme.primaryWhite,
                    ),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 6),

          /// FIELD
          CompositedTransformTarget(
            link: _layerLink,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 52,
              key: _fieldKey,
              decoration: _getDecoration(),

              child: Row(
                children: [
                  if (widget.showPrefixIcon && widget.prefixIcon != null) ...[
                    const SizedBox(width: 6),

                    Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: () {
                        if (widget.fieldState == FusionFieldState.blocked)
                          return context.colorScheme.iconDisabled;
                        else if (widget.fieldState ==
                            FusionFieldState.blockedFilled)
                          return context.colorScheme.iconDisabled;
                        else
                          return context.colorScheme.textPrimary;
                      }(),
                    ),
                  ],
                  if (widget.showCountryCode) ...[
                    GestureDetector(
                      onTap: widget.enabled ? _showCountryCodePicker : null,
                      child: Container(
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 12,
                        //   vertical: 14,
                        // ),
                        decoration: BoxDecoration(
                          color: widget.enabled
                              ? Colors.transparent
                              : context.colorScheme.elevation1.withOpacity(
                                  0.5,
                                ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountryCode,
                              style: TextStyle(
                                color:
                                    widget.fieldState ==
                                        FusionFieldState.blocked
                                    ? context.colorScheme.textDisabled
                                    : widget.fieldState ==
                                          FusionFieldState.blockedFilled
                                    ? context.colorScheme.textBody
                                    : context.colorScheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: () {
                                if (widget.fieldState ==
                                    FusionFieldState.blocked)
                                  return context.colorScheme.iconDisabled;
                                else if (widget.fieldState ==
                                    FusionFieldState.blockedFilled)
                                  return context.colorScheme.iconDisabled;
                                else
                                  return context.colorScheme.textPrimary;
                              }(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      height: 22,
                      width: 1,
                      color: context.colorScheme.strokeDark,
                    ),
                  ],

                  if (widget.showRupee) ...[
                    const SizedBox(width: 6),

                    Icon(
                      Icons.currency_rupee,
                      size: 14,
                      color: widget.fieldState == FusionFieldState.blocked
                          ? context.colorScheme.textDisabled
                          : widget.fieldState == FusionFieldState.blockedFilled
                          ? context.colorScheme.textBody
                          : widget.fieldState == FusionFieldState.defaultState
                          ? context.colorScheme.textPlaceholder
                          : context.colorScheme.textPrimary,
                    ),
                  ],
                  Expanded(
                    child: widget.isDropdown
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.enabled
                                ? () {
                                    FocusScope.of(context).unfocus();
                                    _toggleDropdown();
                                  }
                                : null,
                            child: Container(
                              // alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 10,
                              ),
                              color: _fillColor(),
                              child: Text(
                                widget.controller.text.isEmpty
                                    ? widget.hint
                                    : widget.controller.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.controller.text.isEmpty
                                      ? context.colorScheme.textPlaceholder
                                      : context.colorScheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        : IgnorePointer(
                            ignoring:
                                widget.fieldState == FusionFieldState.blocked
                                ? true
                                : !widget.enabled,
                            child: TextField(
                              controller: widget.controller,
                              focusNode: _focusNode,

                              enabled: widget.enabled,

                              readOnly:
                                  widget.fieldState == FusionFieldState.blocked
                                  ? true
                                  : !widget.enabled,
                              showCursor:
                                  widget.fieldState == FusionFieldState.blocked
                                  ? false
                                  : !widget.isDropdown,

                              onTap: () {
                                if (widget.isDropdown) {
                                  _toggleDropdown();
                                } else {
                                  widget.onTap?.call();
                                }
                              },

                              keyboardType:
                                  widget.inputType ?? TextInputType.text,

                              inputFormatters:
                                  widget.inputType == TextInputType.phone
                                  ? [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ]
                                  : null,

                              // Prevent all input when blocked
                              onChanged: widget.enabled
                                  ? null
                                  : (value) {
                                      // Block any changes
                                      widget.controller.text =
                                          widget.controller.text;
                                      widget.controller.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset:
                                                  widget.controller.text.length,
                                            ),
                                          );
                                    },

                              // Prevent submit when blocked
                              onSubmitted: widget.enabled
                                  ? null
                                  : (value) {
                                      // Do nothing when blocked
                                    },

                              style: TextStyle(
                                color:
                                    widget.fieldState ==
                                        FusionFieldState.blocked
                                    ? context.colorScheme.elevation1
                                    : widget.fieldState ==
                                          FusionFieldState.blockedFilled
                                    ? context.colorScheme.elevation1
                                    : context.colorScheme.primaryWhite,
                                fontSize: 14,
                              ),

                              decoration: InputDecoration(
                                hoverColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,

                                hintText: widget.hint,
                                hintStyle: TextStyle(
                                  color:
                                      widget.fieldState ==
                                          FusionFieldState.blocked
                                      ? context.colorScheme.textDisabled
                                      : widget.fieldState ==
                                            FusionFieldState.blockedFilled
                                      ? context.colorScheme.textBody
                                      : Colors.transparent,
                                ),

                                fillColor: context.colorScheme.elevation1,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                  ),

                  /// BUTTON
                  if (widget.button)
                    NeumorphicButton(
                      height: 32,
                      semanticId: 'textfield_button',
                      borderRadius: 8,
                      onTap: widget.buttonTap ?? () {},
                      text: widget.buttonText,
                      width: 100,
                      color: context.colorScheme.elevation1,
                      textStyle: TextStyle(
                        color: context.colorScheme.textPrimary,
                      ),
                    ),

                  /// SUFFIX
                  if (widget.showSuffixIcon && widget.suffixIcon != null) ...[
                    const SizedBox(width: 6),

                    Icon(
                      widget.suffixIcon,
                      size: 20,
                      color: widget.fieldState == FusionFieldState.blocked
                          ? context.colorScheme.iconDisabled
                          : widget.fieldState == FusionFieldState.blockedFilled
                          ? context.colorScheme.iconDisabled
                          : context.colorScheme.textPrimary,
                    ),
                  ],
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          /// MESSAGES
          if (widget.hasHelperText)
            Text(
              widget.helperText,
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.textPrimary,
              ),
            ),

          if (widget.hasErrorText)
            Text(
              widget.errorText,
              style: TextStyle(
                color: context.colorScheme.errorText,
                fontSize: 12,
              ),
            ),

          if (widget.hasSuccessText)
            Text(
              widget.successText,
              style: TextStyle(
                color: context.colorScheme.successText,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
