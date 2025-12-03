import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../search_bar_sources.dart';

class ActionList extends StatelessWidget {
  const ActionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,

        border: Border(
          left: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Header with Search Bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  alignment: Alignment.center,

                  // width 30% of the parent width
                  width: MediaQuery.of(context).size.width * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(width: 1, color: Theme.of(context).colorScheme.grey),
                    ),
                  ),
                  child: SearchBarSources(
                    searchController: TextEditingController(),
                    isFromActionList: true,
                    hasActiveFilters: () => false,
                    onClearSearch: () {},
                    onSearchChanged: (String value) {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
