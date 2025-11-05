import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/dto/pb_item.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:provider/provider.dart';

import '../viewmodel/pbc_viewmodel.dart';
import 'item_widget_builder.dart';

class ProcessingBlockCustomizer extends StatelessWidget {
  const ProcessingBlockCustomizer({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PbcViewmodel>(
      create: (BuildContext context) => PbcViewmodel(),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: _PBCItemList(),
          ),
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double wpc = constraints.maxWidth / 100;
                  return Consumer<PbcViewmodel>(
                    builder: (BuildContext context, PbcViewmodel viewModel, Widget? child) {
                      return FusionKeyboardWrapper(
                        onDelete: () {
                          viewModel.delete();
                        },
                        onDown: () {
                          viewModel.move(const Offset(0, 2));
                        },
                        onLeft: () {
                          viewModel.move(const Offset(-2, 0));
                        },
                        onRight: () {
                          viewModel.move(const Offset(2, 0));
                        },
                        onUp: () {
                          viewModel.move(const Offset(0, -2));
                        },
                        child: DragTarget<String>(
                          onAcceptWithDetails: (DragTargetDetails<String> details) {
                            viewModel.addItem(details.data, details.offset / wpc);
                          },
                          builder: (BuildContext context, List<String?> candidateData, List<dynamic> rejectedData) {
                            return Stack(
                              children: <Widget>[
                                for (final PBItem child in viewModel.items)
                                  Positioned(
                                    left: wpc * child.x,
                                    top: wpc * child.y,
                                    child: Container(
                                      width: wpc * child.width,
                                      height: wpc * child.height,
                                      decoration: viewModel.selected == child ? BoxDecoration(border: Border.all(color: Colors.black)) : const BoxDecoration(),
                                      child: InkWell(
                                        onTap: () {
                                          viewModel.selected = child;
                                        },

                                        child: GestureDetector(
                                          onPanUpdate: (DragUpdateDetails details) {
                                            viewModel.move(details.delta / wpc);
                                          },
                                          child: AbsorbPointer(absorbing: true, child: ItemWidgetBuilder(item: child)),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Consumer<PbcViewmodel>(
              builder: (BuildContext context, PbcViewmodel viewModel, Widget? child) {
                final Map<String, dynamic>? selected = viewModel.selected?.param.toMap();
                return ListView(
                  key: ValueKey<Map<String, dynamic>?>(selected),
                  padding: const EdgeInsets.all(8),
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (BuildContext context) => Dialog(
                                child: Text(jsonEncode(viewModel.currentJson)),
                              ),
                        );
                      },
                      icon: const Icon(Icons.save),
                    ),
                    for (final String key in selected?.keys ?? <String>[])
                      Row(
                        spacing: 10,
                        children: <Widget>[
                          Text(key),
                          Expanded(
                            child: TextFormField(
                              initialValue: selected?[key]?.toString(),
                              onFieldSubmitted: (String? newValue) {
                                viewModel.updateProperty(key, newValue ?? "");
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PBCItemList extends StatelessWidget {
  const _PBCItemList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: ListView(
        children: <Widget>[
          ...<String>[
            'switch',
            'indicator',
            'empty',
            'text',
            'slider',
            'graph',
          ].map(
            (String e) => Draggable<String>(
              data: e,
              feedback: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text(e)),
                ),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text(e)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
