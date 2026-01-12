import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/utils/broadcast_controllers.dart';
import 'package:fusion_launcher/features/scheduling/view/widgets/calender_view.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_text_button.dart';
import 'package:intl/intl.dart';

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
    return BlocProvider<SchedulerViewmodel>(
      create: (BuildContext context) => SchedulerViewmodel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ///--------------------------------------------------------------------------------------------
          ///
          /// Header Section
          ///
          ///--------------------------------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: <Widget>[
                const SizedBox(
                  width: 10,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    switch (_currentPage) {
                      _PageType.timeline => "Timeline",
                      _PageType.scheduler => "Scheduler",
                    },
                    style: context.textTheme.titleLarge,
                  ),
                ),
                // const StatusChip(),
                const Spacer(),
                // OutlinedButton(onPressed: () {}, child: const Text("Share")),
                // FusionOutlinedButton(label: "Share", onTap: () {}),
                BlocBuilder<SchedulerViewmodel, SchedulerState>(
                  builder: (BuildContext context, SchedulerState state) {
                    return FusionButton(
                      label: "+",
                      width: 36,
                      onTap: () {
                        SchedulerForm.show(
                          context,
                          context.read<SchedulerViewmodel>(),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),

          ///--------------------------------------------------------------------------------------------
          ///
          /// Tabbar Header
          ///
          ///--------------------------------------------------------------------------------------------
          Row(
            spacing: 10,
            children: <Widget>[
              Row(
                spacing: 10,
                children: <Widget>[
                  const SizedBox(
                    width: 20,
                  ),
                  InkWell(
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
                  const SizedBox(
                    width: 10,
                  ),
                  InkWell(
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
                          hintText: "Search",
                          autofocus: true,
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.black,
                          ),
                          suffixIcon: InkWell(
                            onTap: () {
                              context.read<SchedulerViewmodel>().idle();
                            },
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.black,
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
                        InkWell(
                          onTap: () {
                            BlocProvider.of<SchedulerViewmodel>(context).searchSchedules("");
                          },
                          child: const _ActionButton(
                            title: "Search",
                            icon: Icons.search,
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

              //
              // Right Side Actions
              //
              const SizedBox(
                width: 10,
              ),
            ],
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
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
    final Color fgColor = isSelected ? Colors.black : Colors.grey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isSelected ? fgColor : Colors.transparent, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        child: Row(
          spacing: 5,
          children: <Widget>[
            SvgPicture.asset(
              icon,
              colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
              width: 16,
              height: 16,
            ),
            Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
