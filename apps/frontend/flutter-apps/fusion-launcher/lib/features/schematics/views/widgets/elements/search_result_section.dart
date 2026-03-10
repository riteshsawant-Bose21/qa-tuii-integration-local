import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/schematics/state/search_state.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../viewmodel/search_control_viewmodel.dart';

class SchematicSearchResultSection extends StatelessWidget {
  const SchematicSearchResultSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchControlViewModel, SearchState>(
      builder: (BuildContext context, SearchState searchingState) {
        if (searchingState is! SearchingState) {
          return const SizedBox();
        }
        if (searchingState.searchQuery.isEmpty) {
          return const SizedBox();
        }
        return BlocBuilder<SearchResultsViewModel, SearchResultState>(
          builder: (BuildContext context, SearchResultState state) {
            return SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "search_results_message_container"),
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 6.0, right: 16.0),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.black87),
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${state.results.length} results found for ',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.primaryWhite,
                        ),
                      ),
                      TextSpan(
                        text: '"${state.query}"',
                        style: context.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          backgroundColor: Colors.orange[200],
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
