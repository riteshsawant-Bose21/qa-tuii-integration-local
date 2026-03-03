import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_flat_container.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nested/nested.dart';

import '../../state/search_state.dart';
import '../../viewmodel/search_control_viewmodel.dart';
import 'elements/search_result_section.dart';

class SchematicListingSection extends StatefulWidget {
  final String sectionTitle;
  final String? searchHint;
  final Widget? action;
  final List<Widget> sections;
  const SchematicListingSection({
    super.key,
    required this.sectionTitle,
    this.searchHint,
    required this.sections,
    this.action,
  });

  @override
  State<SchematicListingSection> createState() =>
      _SchematicListingSectionState();
}

class _SchematicListingSectionState extends State<SchematicListingSection> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<SearchControlViewModel>(
          create: (_) => SearchControlViewModel(),
        ),
        BlocProvider<SearchResultsViewModel>(
          create: (_) => SearchResultsViewModel(),
        ),
      ],
      child: FusionFlatContainer(
        semanticId: SemanticHelper.createTestId(
          SemanticTypes.container,
          "expandable_section_container_${widget.sectionTitle.toLowerCase()}",
        ),
        padding: EdgeInsets.zero,
        child: BlocBuilder<SearchControlViewModel, SearchState>(
          builder: (BuildContext context, SearchState state) {
            final SearchControlViewModel viewModel =
                context.watch<SearchControlViewModel>();
            final bool showSearchBar = state is SearchingState;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ///
                /// ---------------------------------------------------------------------------------------------------------------------
                ///.    1. Top Header with Search bar
                /// ---------------------------------------------------------------------------------------------------------------------
                ///
                ///
                SemanticHelper.container(
                  testId: SemanticHelper.createTestId(
                    SemanticTypes.container,
                    "expandable_section_header_container_${widget.sectionTitle.toLowerCase()}",
                  ),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      spacing: 8.0,
                      children: <Widget>[
                        Expanded(
                          child: ClipRect(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              layoutBuilder: (
                                Widget? currentChild,
                                List<Widget> previousChildren,
                              ) {
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: <Widget>[
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      ),
                              child:
                                  (state is SearchingState)
                                      ? SemanticHelper.formControl(
                                        testId: SemanticHelper.createTestId(
                                          SemanticTypes.textInput,
                                          "section_search_${widget.sectionTitle.toLowerCase()}",
                                        ),
                                        child: FusionTextField(
                                          semanticFieldId:
                                              'section_search_${widget.sectionTitle.toLowerCase()}',
                                          focusNode: viewModel.focusNode,
                                          controller: viewModel.controller,
                                          style: context.textTheme.labelSmall,
                                          color: context.colorScheme.elevation2,
                                          hintText:
                                              widget.searchHint ??
                                              "Search ${widget.sectionTitle.toLowerCase()}",
                                        ),
                                      )
                                      : FusionAppText(
                                        text: widget.sectionTitle.toUpperCase(),
                                        maxLine: 1,
                                        textAlign: TextAlign.start,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: FusionSizes.fontSize12,
                                              color:
                                                  context.colorScheme.textBody,
                                            ),
                                      ),
                            ),
                          ),
                        ),
                        if (widget.action != null) widget.action!,
                        SemanticHelper.button(
                          testId: SemanticHelper.createTestId(
                            SemanticTypes.button,
                            showSearchBar
                                ? "${widget.sectionTitle.toLowerCase()}_search_close_icon"
                                : "${widget.sectionTitle.toLowerCase()}_search_icon",
                          ),
                          child: InkWell(
                            onTap: () {
                              if (showSearchBar) {
                                viewModel.cancel();
                              } else {
                                viewModel.initiateSearch();
                              }
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),

                              child: Icon(
                                key: ValueKey<bool>(showSearchBar),
                                showSearchBar
                                    ? LucideIcons.x200
                                    : LucideIcons.search200,
                                size: FusionSizes.iconSize16,
                                color: context.colorScheme.primaryWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(
                  height: 1,
                  color: context.colorScheme.elevation2,
                ),
                const SizedBox(
                  height: 8,
                ),
                const SchematicSearchResultSection(),

                ///
                /// ---------------------------------------------------------------------------------------------------------------------
                ///.    2.  Content Area
                /// ---------------------------------------------------------------------------------------------------------------------
                ///
                ///
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      ...widget.sections,
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
