import 'package:flutter/material.dart';
import 'package:fusion_app/features/events/models/event_model.dart';
import 'package:fusion_app/features/events/presentation/events_screen.dart';
import 'package:fusion_app/features/project/presentation/configuration/widgets/item_expandable_group.dart';
import 'package:fusion_app/features/project/presentation/configuration/widgets/section_title.dart';
import 'package:fusion_app/features/project/presentation/configuration/widgets/item_source.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class SourcesTabScreen extends StatefulWidget {
  final List<EventModel> events;
  const SourcesTabScreen({this.events = const [], super.key});

  @override
  State<SourcesTabScreen> createState() => _SourcesTabScreenState();
}

class _SourcesTabScreenState extends State<SourcesTabScreen> {
  final List<SourceItem> primarySources = [];
  final List<SourceGroup> sourceGroups = [];
  @override
  void initState() {
    primarySources.addAll([
      SourceItem(id: 'paging_mic', name: 'Paging Mic', icon: Icons.mic),
      SourceItem(
        id: 'message_player',
        name: 'Message Player',
        icon: Icons.play_circle_outline,
        hasLink: true,
      ),
    ]);

    sourceGroups.addAll([
      SourceGroup(
        id: 'mics',
        title: 'MICS',
        sources: [
          SourceItem(
            id: 'wireless_mic_1',
            name: 'Wireless Mic 1',
            icon: Icons.mic,
          ),
          SourceItem(
            id: 'wireless_mic_2',
            name: 'Wireless Mic 2',
            icon: Icons.mic,
          ),
        ],
      ),
      SourceGroup(
        id: 'music',
        title: 'MUSIC',
        sources: [
          SourceItem(id: 'music_drive', name: 'Music Drive', icon: Icons.usb),
          SourceItem(id: 'spotify', name: 'Spotify', icon: Icons.music_note),
          SourceItem(id: 'youtube', name: 'YouTube', icon: Icons.play_arrow),
        ],
      ),
    ]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      //padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.perm_data_setting_sharp,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              SizedBox(width: 10),
              Text(
                "Processing",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 5),
              Spacer(),
              Icon(
                Icons.keyboard_arrow_down_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: context.colorScheme.elevation1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('SOURCES'),
              CommonDivider(paddingValue: 0),
              // 🔹 Primary Sources
              ...primarySources.map(
                (source) => Container(
                  margin: EdgeInsets.symmetric(vertical: 16),
                  child: SourceRow(
                    icon: source.icon,
                    title: source.name,
                    showLink: source.hasLink,
                    showSettings: source.hasSettings,
                  ),
                ),
              ),
              CommonDivider(paddingValue: 0),
              const SectionTitle('SOURCE SETS'),
              CommonDivider(paddingValue: 0),
              // 🔹 Expandable Groups
              ...sourceGroups.map(
                (group) => Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: FusionContainer(
                    color: const Color(0xFF1A1A18),
                    raised: true,
                    child: ExpandableGroup(
                      expanded: false,
                      onToggle: () {},
                      // onToggle: () {
                      //   setState(() => expanded = !expanded);
                      // },
                      title: group.title,
                      children: group.sources
                          .map(
                            (source) => Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: SourceRow(
                                icon: source.icon,
                                title: source.name,
                                showSettings: source.hasSettings,
                                listMeters: ["1","2"],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SourceGroup {
  final String id;
  final String title;
  final List<SourceItem> sources;

  const SourceGroup({
    required this.id,
    required this.title,
    required this.sources,
  });
}

class SourceItem {
  final String id;
  final String name;
  final IconData icon;
  final bool hasLink;
  final bool hasSettings;

  const SourceItem({
    required this.id,
    required this.name,
    required this.icon,
    this.hasLink = false,
    this.hasSettings = true,
  });
}
