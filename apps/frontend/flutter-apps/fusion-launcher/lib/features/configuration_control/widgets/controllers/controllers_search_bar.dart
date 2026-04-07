import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_state.dart';
import 'package:fusion_launcher/features/configuration_control/viewModel/configuration_control_viewmodel.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// Search bar widget for filtering controllers
class ControllersSearchBar extends StatefulWidget {
  const ControllersSearchBar({super.key});

  @override
  State<ControllersSearchBar> createState() => _ControllersSearchBarState();
}

class _ControllersSearchBarState extends State<ControllersSearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigurationControlViewmodel, ConfigurationControlState>(
      buildWhen: (ConfigurationControlState previous, ConfigurationControlState current) {
        return previous.searchQuery != current.searchQuery;
      },
      builder: (BuildContext context, ConfigurationControlState state) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            border: Border(
              left: BorderSide(color: context.colorScheme.elevation2, width: 1),
              right: BorderSide(color: context.colorScheme.elevation2, width: 1),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.colorScheme.elevation2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FusionIcon.icon(
                          Icons.search,
                          size: 16,
                          color: context.colorScheme.iconDefault,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: Theme.of(context).textTheme.bodySmall,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.textPlaceholder,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (String value) {
                            context.read<ConfigurationControlViewmodel>().updateSearchQuery(value);
                          },
                        ),
                      ),
                      if (state.searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            context.read<ConfigurationControlViewmodel>().clearSearch();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FusionIcon.icon(
                              Icons.close,
                              size: 14,
                              color: context.colorScheme.iconDefault,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              /// Filter button
              GestureDetector(
                onTap: () {
                  // TODO: Implement filter functionality
                },
                child: FusionIcon.icon(
                  Icons.filter_list,
                  size: 18,
                  color: context.colorScheme.iconDefault,
                ),
              ),
              const SizedBox(width: 8),

              /// Sort button
              GestureDetector(
                onTap: () {
                  // TODO: Implement sort functionality
                },
                child: FusionIcon.icon(
                  Icons.swap_vert,
                  size: 18,
                  color: context.colorScheme.iconDefault,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
