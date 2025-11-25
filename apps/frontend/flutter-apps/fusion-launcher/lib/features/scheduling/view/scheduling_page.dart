import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/fusion_widgets.dart';

import 'sections/scheduler_form.dart';
import 'widgets/status_chip.dart';

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
  _PageType _currentPage = _PageType.timeline;
  @override
  Widget build(BuildContext context) {
    return Column(
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
              const StatusChip(),
              const Spacer(),
              // OutlinedButton(onPressed: () {}, child: const Text("Share")),
              FusionOutlinedButton(label: "Share", onTap: () {}),
              FusionButton(
                label: "Create",
                onTap: () {
                  SchedulerForm.show(context);
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

            //
            // Right Side Actions
            //
            const _ActionButton(
              title: "Search",
              icon: Icons.search,
            ),
            const _ActionButton(
              title: "Filter",
              icon: Icons.filter_list,
            ),
            const _ActionButton(
              title: "Sort",
              icon: Icons.unfold_more,
            ),
            const _ActionButton(
              title: "Fields",
              icon: Icons.list_rounded,
            ),
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
