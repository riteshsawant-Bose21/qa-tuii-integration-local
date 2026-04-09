

import 'package:flutter/cupertino.dart';

class EventModel {
  final String time;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool enabled;
  final bool showDeleteIcon;
  final bool showSwitchIcon;

  const EventModel({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.enabled=false,
    this.showDeleteIcon=false,
    this.showSwitchIcon=false,
  });

  EventModel copyWith({
    String? time,
    String? title,
    String? subtitle,
    Color? accentColor,
    bool? enabled,
    bool? showDeleteIcon,
    bool? showSwitchIcon
  }) {
    return EventModel(
      time: time ?? this.time,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      accentColor: accentColor ?? this.accentColor,
      enabled: enabled ?? this.enabled,
      showDeleteIcon: showDeleteIcon ?? this.showDeleteIcon,
      showSwitchIcon: showSwitchIcon ?? this.showSwitchIcon,
    );
  }


}