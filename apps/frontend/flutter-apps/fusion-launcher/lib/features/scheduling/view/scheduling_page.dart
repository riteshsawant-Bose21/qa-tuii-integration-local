import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/scheduling/model/calendar_event.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/calender_view.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/event_card.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/WeekDayHeader.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/fusion_utils.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../state/scheduler_state.dart';
import '../state/timeline_state.dart';
import '../viewmodel/scheduler_viewmodel.dart';
import '../viewmodel/timeline_viewmodel.dart';
import 'sections/scheduler_form.dart';

part 'sections/scheduler_section.dart';
part 'sections/timeline_section.dart';

enum _PageType {
  timeline,
  scheduler,
}

class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});

  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage> {
  _PageType _currentPage = _PageType.scheduler;
  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'scheduling_page'),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          border: Border.all(width: 1, color: context.colorScheme.elevation2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: BlocProvider<SchedulerViewmodel>(
          create: (BuildContext context) => SchedulerViewmodel(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ///--------------------------------------------------------------------------------------------
              ///
              /// Header Section
              ///
              ///--------------------------------------------------------------------------------------------
              SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, 'scheduling_page_header'),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    border: Border(
                      bottom: BorderSide(
                        color: context.colorScheme.strokeLight,
                        width: 1,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: <Widget>[
                      ///  tabs for scheduler and timeline
                      Row(
                        spacing: 10,
                        children: <Widget>[
                          SemanticHelper.button(
                            testId: SemanticHelper.createTestId(
                              SemanticTypes.button,
                              "scheduler_tab_button",
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentPage = _PageType.scheduler;
                                });
                              },
                              child: _TabHeader(
                                title: "Scheduler",
                                icon: 'assets/icons/scheduler/scheduler.svg',
                                isSelected: _currentPage == _PageType.scheduler,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          SemanticHelper.button(
                            testId: SemanticHelper.createTestId(
                              SemanticTypes.button,
                              "timeline_tab_button",
                            ),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentPage = _PageType.timeline;
                                });
                              },
                              child: _TabHeader(
                                title: "Timeline",
                                icon: 'assets/icons/scheduler/timeline.svg',
                                isSelected: _currentPage == _PageType.timeline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: BlocBuilder<SchedulerViewmodel, SchedulerState>(
                          builder: (BuildContext context, SchedulerState state) {
                            if (state is SearchingSchedulerState) {
                              return SizedBox(
                                width: 200,
                                child: FusionTextField(
                                  semanticFieldId: 'scheduler_search_field',
                                  hintText: "Search",
                                  autofocus: true,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 20,
                                    color: context.colorScheme.iconWhite,
                                  ),
                                  suffixIcon: SemanticHelper.button(
                                    testId: SemanticHelper.createTestId(
                                      SemanticTypes.button,
                                      "search_close_button",
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        context.read<SchedulerViewmodel>().idle();
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 20,
                                        color: context.colorScheme.iconWhite,
                                      ),
                                    ),
                                  ),
                                  onChanged: (String query) {
                                    context.read<SchedulerViewmodel>().searchSchedules(query);
                                  },
                                ),
                              );
                            }
                            return Row(
                              children: <Widget>[
                                SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(
                                    SemanticTypes.button,
                                    "search_button",
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      BlocProvider.of<SchedulerViewmodel>(
                                        context,
                                      ).searchSchedules("");
                                    },
                                    child: const _ActionButton(
                                      title: "Search",
                                      icon: Icons.search,
                                    ),
                                  ),
                                ),
                                // const _ActionButton(
                                //   title: "Filter",
                                //   icon: Icons.filter_list,
                                // ),
                                // const _ActionButton(
                                //   title: "Sort",
                                //   icon: Icons.unfold_more,
                                // ),
                                // const _ActionButton(
                                //   title: "Fields",
                                //   icon: Icons.list_rounded,
                                // ),
                              ],
                            );
                          },
                        ),
                      ),

                      /// Add new schedule button
                      BlocBuilder<SchedulerViewmodel, SchedulerState>(
                        builder: (BuildContext context, SchedulerState state) {
                          return InkWell(
                            child: FusionIcon.icon(
                              semanticId: 'scheduling_header_add_icon',
                              Icons.add,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              SchedulerForm.show(
                                context,
                                context.read<SchedulerViewmodel>(),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),

              ///--------------------------------------------------------------------------------------------
              ///
              /// Body Section
              ///
              ///--------------------------------------------------------------------------------------------
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (_currentPage) {
                    _PageType.timeline => const _TimelineSection(),
                    _PageType.scheduler => const _SchedulerSection(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    required this.icon,
    required this.isSelected,
  });
  final String title;
  final String icon;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    final Color fgColor = isSelected ? context.colorScheme.textPrimary : context.colorScheme.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? context.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 24),
        child: Row(
          spacing: 5,
          children: <Widget>[
            SvgPicture.asset(
              semanticsLabel: 'scheduler_tab_header_icon',
              icon,
              colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
              width: 12,
              height: 12,
            ),
            FusionAppText(semanticId: 'scheduler_tab_header_text', text: title, style: context.textTheme.l1Medium),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.icon,
  });
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        spacing: 5,
        children: <Widget>[
          FusionIcon.icon(
            semanticId: 'action_button_icon',
            icon,
            size: 16,
            color: Colors.grey,
          ),
          FusionAppText(
            semanticId: 'action_button_text',
            text: title,
            style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
