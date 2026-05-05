import 'dart:math' as math;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

class CalendarWithOverlayPickers extends StatefulWidget {
  const CalendarWithOverlayPickers({
    super.key,
    required this.selectedDate,
    required this.minDate,
    required this.onPicked,
    required this.baseDayStyle,
  });

  final DateTime? selectedDate;
  final DateTime? minDate;
  final ValueChanged<DateTime> onPicked;
  final TextStyle baseDayStyle;

  @override
  State<CalendarWithOverlayPickers> createState() => CalendarWithOverlayPickersState();
}

class CalendarWithOverlayPickersState extends State<CalendarWithOverlayPickers> {
  late DateTime _displayedMonth;
  final LayerLink _monthLink = LayerLink();
  final LayerLink _yearLink = LayerLink();
  final OverlayPortalController _monthController = OverlayPortalController();
  final OverlayPortalController _yearController = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    final DateTime initial = widget.selectedDate ?? DateTime.now();
    final DateTime floor = _minAllowedMonth();
    _displayedMonth = DateTime(initial.year, initial.month, 1).isBefore(floor) ? floor : DateTime(initial.year, initial.month, 1);
  }

  DateTime _minAllowedMonth() {
    final DateTime min = widget.minDate ?? DateTime.now();
    return DateTime(min.year, min.month, 1);
  }

  bool get _canGoBack {
    final DateTime prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    return !prev.isBefore(_minAllowedMonth());
  }

  void _toggleMonth() {
    if (_yearController.isShowing) _yearController.hide();
    if (_monthController.isShowing) {
      _monthController.hide();
    } else {
      _monthController.show();
    }
    setState(() {});
  }

  void _toggleYear() {
    if (_monthController.isShowing) _monthController.hide();
    if (_yearController.isShowing) {
      _yearController.hide();
    } else {
      _yearController.show();
    }
    setState(() {});
  }

  void _selectMonth(int month) {
    final DateTime candidate = DateTime(_displayedMonth.year, month, 1);
    if (candidate.isBefore(_minAllowedMonth())) return;
    setState(() => _displayedMonth = candidate);
    _monthController.hide();
  }

  void _selectYear(int year) {
    final DateTime floor = _minAllowedMonth();
    final DateTime candidate = DateTime(year, _displayedMonth.month, 1);
    final DateTime adjusted = candidate.isBefore(floor) ? DateTime(year, floor.month, 1) : candidate;
    // If year < floor.year entirely, ignore (disabled in picker anyway).
    if (adjusted.isBefore(floor)) return;
    setState(() => _displayedMonth = adjusted);
    _yearController.hide();
  }

  void _prevMonth() {
    if (!_canGoBack) return;
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  void dispose() {
    if (_monthController.isShowing) _monthController.hide();
    if (_yearController.isShowing) _yearController.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime floor = _minAllowedMonth();
    final bool canGoBack = _canGoBack;

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: context.colorScheme.strokeLight,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// Custom header
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, 'calendar_header'),
            child: Row(
              children: <Widget>[
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, 'calendar_header_month_container'),
                  child: CompositedTransformTarget(
                    link: _monthLink,
                    child: OverlayPortal(
                      controller: _monthController,
                      overlayChildBuilder: (BuildContext ctx) {
                        final Set<int> disabled = <int>{};
                        for (int i = 0; i < 12; i++) {
                          final DateTime candidate = DateTime(_displayedMonth.year, i + 1, 1);
                          if (candidate.isBefore(floor)) disabled.add(i);
                        }
                        return _FloatingGridPicker(
                          semanticId: 'month',
                          link: _monthLink,
                          width: 244,
                          scrollable: false,
                          items: List<String>.generate(
                            12,
                            (int i) => _monthShort(i + 1),
                          ),
                          selectedIndex: _displayedMonth.month - 1,
                          disabledIndices: disabled,
                          onSelected: (int i) => _selectMonth(i + 1),
                          onDismiss: () {
                            _monthController.hide();
                            setState(() {});
                          },
                        );
                      },
                      child: _buildHeaderChip(
                        label: _monthName(_displayedMonth.month),
                        isOpen: _monthController.isShowing,
                        onTap: _toggleMonth,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, 'calendar_header_year_container'),
                  child: CompositedTransformTarget(
                    link: _yearLink,
                    child: OverlayPortal(
                      controller: _yearController,
                      overlayChildBuilder: (BuildContext ctx) {
                        final int currentYear = DateTime.now().year;
                        final int floorYear = floor.year;

                        // Build a wide year range that always includes the currently displayed year
                        final int startYear = floorYear;
                        final int endYear = math.max(currentYear + 20, _displayedMonth.year + 5);
                        final List<int> years = <int>[
                          for (int y = startYear; y <= endYear; y++) y,
                        ];

                        final int selectedIdx = years.indexOf(_displayedMonth.year);
                        return _FloatingGridPicker(
                          semanticId: 'year',
                          offset: const Offset(-70, 6),
                          link: _yearLink,
                          width: 244,
                          scrollable: true,
                          items: years.map((int y) => y.toString()).toList(),
                          selectedIndex: selectedIdx,
                          disabledIndices: const <int>{},
                          onSelected: (int i) => _selectYear(years[i]),
                          onDismiss: () {
                            _yearController.hide();
                            setState(() {});
                          },
                        );
                      },
                      child: _buildHeaderChip(
                        label: _displayedMonth.year.toString(),
                        isOpen: _yearController.isShowing,
                        onTap: _toggleYear,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: canGoBack ? _prevMonth : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FusionIcon.icon(
                      Icons.chevron_left,
                      size: 20,
                      color: canGoBack ? context.colorScheme.iconDefault : context.colorScheme.iconDefault.withAlpha(35),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _nextMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FusionIcon.icon(
                      Icons.chevron_right,
                      size: 20,
                      color: context.colorScheme.iconDefault,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 0.77,
              child: CalendarDatePicker2(
                config: CalendarDatePicker2Config(
                  dayBuilder: ({
                    required DateTime date,
                    BoxDecoration? decoration,
                    bool? isDisabled,
                    bool? isSelected,
                    bool? isToday,
                    TextStyle? textStyle,
                  }) {
                    if (isSelected == true) return null; // keep default selected style

                    return MouseRegion(
                      cursor: isDisabled == true ? SystemMouseCursors.basic : SystemMouseCursors.click,
                      child: _HoverableDay(
                        date: date,
                        isDisabled: isDisabled ?? false,
                        isToday: isToday ?? false,
                        baseDayStyle: widget.baseDayStyle,
                      ),
                    );
                  },
                  calendarType: CalendarDatePicker2Type.single,
                  firstDate: widget.minDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  disableModePicker: true,
                  hideMonthPickerDividers: true,
                  hideYearPickerDividers: true,
                  selectedDayHighlightColor: context.colorScheme.primaryWhite,
                  selectedDayTextStyle: widget.baseDayStyle.copyWith(
                    color: context.colorScheme.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                  daySplashColor: Colors.white10,
                  dayTextStyle: widget.baseDayStyle,
                  disabledDayTextStyle: widget.baseDayStyle.copyWith(
                    color: context.colorScheme.textDisabled,
                  ),
                  todayTextStyle: widget.baseDayStyle,
                  weekdayLabels: const <String>[
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ],
                  weekdayLabelTextStyle: context.textTheme.l1Regular.copyWith(color: context.colorScheme.textSecondary),
                  dayMaxWidth: 22,
                ),
                displayedMonthDate: _displayedMonth,
                value: <DateTime?>[widget.selectedDate],
                onValueChanged: (List<DateTime> dates) {
                  if (dates.isNotEmpty) widget.onPicked(dates.first);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int m) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[m - 1];
  }

  static String _monthShort(int m) {
    const List<String> names = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JLY',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return names[m - 1];
  }

  Widget _buildHeaderChip({
    required String label,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FusionAppText(
              text: label,
              semanticId: 'calendar_header_month_label',
              style: context.textTheme.h6Bold.copyWith(
                color: context.colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            FusionIcon.icon(
              semanticId: 'calendar_header_month_icon',
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: context.colorScheme.iconWhite,
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverableDay extends StatefulWidget {
  const _HoverableDay({
    required this.date,
    required this.isDisabled,
    required this.isToday,
    required this.baseDayStyle,
  });

  final DateTime date;
  final bool isDisabled;
  final bool isToday;
  final TextStyle baseDayStyle;

  @override
  State<_HoverableDay> createState() => _HoverableDayState();
}

class _HoverableDayState extends State<_HoverableDay> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _hovering && !widget.isDisabled ? context.colorScheme.strokeLight : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          '${widget.date.day}',
          style: widget.baseDayStyle.copyWith(
            color: widget.isDisabled ? context.colorScheme.textDisabled : context.colorScheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _FloatingGridPicker extends StatefulWidget {
  const _FloatingGridPicker({
    required this.semanticId,
    required this.link,
    required this.width,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onDismiss,
    this.disabledIndices = const <int>{},
    this.scrollable = false,
    this.offset = const Offset(-6, 6),
  });
  final String semanticId;
  final LayerLink link;
  final double width;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onDismiss;
  final Set<int> disabledIndices;
  final bool scrollable;
  final Offset offset;

  @override
  State<_FloatingGridPicker> createState() => _FloatingGridPickerState();
}

class _FloatingGridPickerState extends State<_FloatingGridPicker> {
  int? _hoveredIndex;
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final Widget grid = SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        '${widget.semanticId}_picker_grid',
      ),
      child: GridView.builder(
        controller: widget.scrollable ? _scrollController : null,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        physics: widget.scrollable ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.9,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = index == widget.selectedIndex;
          final bool isDisabled = widget.disabledIndices.contains(index);
          final bool isHovered = _hoveredIndex == index;

          return MouseRegion(
            cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            onEnter: (_) {
              if (!isDisabled) setState(() => _hoveredIndex = index);
            },
            onExit: (_) {
              if (_hoveredIndex == index) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: InkWell(
              onTap: isDisabled ? null : () => widget.onSelected(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? context.colorScheme.elevation3
                          : isHovered
                          ? context.colorScheme.strokeLight
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FusionAppText(
                  text: widget.items[index],
                  semanticId: 'calendar_header_${widget.semanticId}_item',
                  style: context.textTheme.l1Regular.copyWith(
                    color: isDisabled ? context.colorScheme.textPlaceholder : context.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: const SizedBox.shrink(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: widget.offset,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: widget.width,
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.strokeLight,
                  width: 1,
                ),
              ),
              child:
                  widget.scrollable
                      ? SizedBox(
                        height: 196,
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: grid,
                        ),
                      )
                      : grid,
            ),
          ),
        ),
      ],
    );
  }
}
