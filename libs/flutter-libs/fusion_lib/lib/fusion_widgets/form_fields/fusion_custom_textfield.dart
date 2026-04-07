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

class FusionCustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;

  final bool enabled;
  final bool hasErrorText;
  final String errorText;

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
  final ValueChanged<String>? onSubmit;
  final ValueChanged<String>? onChange;

  final TextInputType? inputType;

  final FusionFieldState? fieldState;
  final FusionFieldVariant variant;
  final bool showRupee;
  final String semanticId;

  final double width;
  final double height;

  final int charlimit;
  final InputDecoration? decoration;

  final double borderRadius;

  const FusionCustomTextField({
    super.key,
    this.width = 400,
    this.height = 52,
    required this.semanticId,
    this.showRupee = false,
    this.label,
    this.hint,
    this.controller,
    this.enabled = true,
    this.hasErrorText = false,
    this.errorText = '',
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
    this.onSubmit,
    this.onChange,
    this.charlimit = 50,
    this.decoration,
    this.borderRadius = 12,
  });

  @override
  State<FusionCustomTextField> createState() => _FusionCustomTextFieldState();
}

/// ---------------- STATE ----------------

class _FusionCustomTextFieldState extends State<FusionCustomTextField> {
  late TextEditingController _internalController;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _dropdownOverlay;

  double _fieldWidth = 0;
  bool _isHovered = false;

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
    _internalController = widget.controller ?? TextEditingController();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeDropdown();
      }

      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });

    _internalController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _removeDropdown();
    if (widget.controller == null) {
      _internalController.dispose();
    }
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

  void _removeDropdown() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  // Add this list at the top of your _FusionCustomTextFieldState class

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
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              color: this.context.colorScheme.elevation3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colorScheme.black.withAlpha(800),
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
                                  style: context.textTheme.b3Regular.withColor(context.colorScheme.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'Search country',
                                    hintStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPlaceholder),
                                    filled: true,
                                    fillColor: const Color(0xFF2A2A2A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: FusionIcon.icon(
                                      Icons.search,
                                      color: this.context.colorScheme.textPlaceholder,
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
                                              style: context.textTheme.b3Regular.withColor(context.colorScheme.textPlaceholder),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: filteredCountries.length,
                                          itemBuilder: (context, index) {
                                            final country = filteredCountries[index];
                                            final isSelected = _selectedCountryCode == country['code'];

                                            return InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedCountryCode = country['code']!;
                                                  _selectedCountry = CountryCode(
                                                    name: country['name'],
                                                    dialCode: country['code'],
                                                    code: country['iso'],
                                                  );
                                                });
                                                _removeDropdown();
                                              },
                                              hoverColor: context.colorScheme.white.withAlpha(300),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? this.context.colorScheme.elevation3.withAlpha(500) : Colors.transparent,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        country['name']!,
                                                        style: context.textTheme.b3Regular.withColor(context.colorScheme.textPrimary),
                                                      ),
                                                    ),
                                                    Text(
                                                      country['code']!,
                                                      style: context.textTheme.b3Regular.withColor(context.colorScheme.textPrimary),
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

    final hasText = _internalController.text.isNotEmpty;

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
    final isHoverActive = _isHovered && widget.enabled;

    if (widget.variant == FusionFieldVariant.neumorphic) {
      return BoxDecoration(
        color: isHoverActive ? context.colorScheme.elevation2 : _fillColor(),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.fieldState == FusionFieldState.focused
            ? [
                BoxShadow(
                  color: context.colorScheme.shadowDark,
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
                BoxShadow(color: context.colorScheme.elevation1),
              ]
            : [
                BoxShadow(
                  color: context.colorScheme.shadowDark,
                  blurRadius: 1,
                  offset: const Offset(-2, -2),
                  blurStyle: BlurStyle.inner,
                ),
                BoxShadow(
                  color: context.colorScheme.shadowLight,
                  blurRadius: 1,
                  offset: const Offset(2, 2),
                  blurStyle: BlurStyle.inner,
                ),
              ],
      );
    }

    return BoxDecoration(
      color: isHoverActive ? context.colorScheme.elevation2 : _fillColor(),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(
        color: isHoverActive ? context.colorScheme.textPrimary : _borderColor(),
        width: 2,
      ),
    );
  }

  bool isFocused(FusionFieldState state) {
    return state == FusionFieldState.focused || state == FusionFieldState.errorFocused;
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
        "textfield_${widget.semanticId}",
      ),
      enabled: widget.enabled,
      focused: isFocused(_getFieldState()),
      value: semanticsValue(_getFieldState()),
      live: _getFieldState() == FusionFieldState.error || _getFieldState() == FusionFieldState.errorFocused,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LABEL
          if (widget.showLabel)
            Row(
              children: [
                FusionAppText(
                  text: widget.label ?? '',
                  style: context.textTheme.l1Medium.withColor(
                    widget.hasErrorText
                        ? context.colorScheme.errorText
                        : widget.fieldState == FusionFieldState.blocked
                        ? context.colorScheme.textDisabled
                        : context.colorScheme.primaryWhite,
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
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Container(
                height: widget.height,
                width: widget.width,
                key: _fieldKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                decoration: _getDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// PREFIX ICON
                    if (widget.showPrefixIcon && widget.prefixIcon != null) ...[
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: widget.fieldState == FusionFieldState.blocked || widget.fieldState == FusionFieldState.blockedFilled
                              ? context.colorScheme.iconDisabled
                              : context.colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    /// COUNTRY CODE
                    if (widget.showCountryCode) ...[
                      GestureDetector(
                        onTap: widget.enabled ? _showCountryCodePicker : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FusionAppText(
                              text: _selectedCountryCode,
                              style: context.textTheme.b3Regular.withColor(
                                widget.fieldState == FusionFieldState.blocked
                                    ? context.colorScheme.textDisabled
                                    : widget.fieldState == FusionFieldState.blockedFilled
                                    ? context.colorScheme.textBody
                                    : context.colorScheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            FusionIcon.icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: widget.fieldState == FusionFieldState.blocked || widget.fieldState == FusionFieldState.blockedFilled
                                  ? context.colorScheme.iconDisabled
                                  : context.colorScheme.textPrimary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        height: widget.height * 0.5,
                        width: 1,
                        color: context.colorScheme.strokeDark,
                      ),

                      const SizedBox(width: 8),
                    ],

                    /// RUPEE
                    if (widget.showRupee) ...[
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
                      const SizedBox(width: 8),
                    ],

                    /// TEXT FIELD
                    Expanded(
                      child: IgnorePointer(
                        ignoring: widget.fieldState == FusionFieldState.blocked ? true : !widget.enabled,
                        child: TextField(
                          maxLength: widget.charlimit,
                          onSubmitted: widget.onSubmit,
                          onChanged: widget.onChange,
                          controller: _internalController,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          readOnly: widget.fieldState == FusionFieldState.blocked ? true : !widget.enabled,
                          maxLines: 1,
                          expands: false,
                          textAlignVertical: TextAlignVertical.center,
                          scrollPadding: EdgeInsets.zero,
                          scrollPhysics: const ClampingScrollPhysics(),

                          keyboardType: widget.inputType ?? TextInputType.text,

                          inputFormatters: widget.inputType == TextInputType.phone
                              ? [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ]
                              : null,
                          style: context.textTheme.b3Regular.withColor(
                            widget.fieldState == FusionFieldState.blocked || widget.fieldState == FusionFieldState.blockedFilled
                                ? context.colorScheme.textDisabled
                                : context.colorScheme.primaryWhite,
                          ),

                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,

                            hintText: widget.hint ?? '',
                            hintStyle: context.textTheme.bodySmall?.withColor(context.colorScheme.textPlaceholder),
                            filled: false,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),

                    /// BUTTON
                    if (widget.button) ...[
                      const SizedBox(width: 8),
                      NeumorphicButton(
                        height: 32,
                        semanticId: 'textfield_button',
                        borderRadius: 8,
                        onTap: widget.buttonTap ?? () {},
                        text: widget.buttonText,
                        width: 100,
                        color: context.colorScheme.elevation1,
                        textStyle: context.textTheme.l1Medium.withColor(
                          context.colorScheme.textPrimary,
                        ),
                      ),
                    ],

                    /// SUFFIX ICON
                    if (widget.showSuffixIcon && widget.suffixIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        widget.suffixIcon,
                        size: 20,
                        color: widget.fieldState == FusionFieldState.blocked || widget.fieldState == FusionFieldState.blockedFilled
                            ? context.colorScheme.iconDisabled
                            : context.colorScheme.textPrimary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          /// MESSAGES
          if (widget.hasHelperText)
            Text(
              widget.helperText,
              style: context.textTheme.l1Regular.withColor(
                context.colorScheme.textPrimary,
              ),
            ),

          if (widget.hasErrorText)
            Text(
              widget.errorText,
              style: context.textTheme.l1Regular.withColor(
                context.colorScheme.errorText,
              ),
            ),

          if (widget.hasSuccessText)
            Text(
              widget.successText,
              style: context.textTheme.l1Regular.withColor(
                context.colorScheme.successText,
              ),
            ),
        ],
      ),
    );
  }
}
