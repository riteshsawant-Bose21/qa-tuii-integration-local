import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/datasource/pb_widgets.dart';
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
            child: Center(
              child: AspectRatio(
                aspectRatio: 840 / 368,
                child: Container(
                  color: Colors.white,
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double wpc = constraints.maxHeight / 100;
                      return Consumer<PbcViewmodel>(
                        builder: (BuildContext context, PbcViewmodel viewModel, Widget? child) {
                          return FusionKeyboardWrapper(
                            onDelete: () {
                              viewModel.delete();
                            },
                            onDown: () {
                              viewModel.move(const Offset(0, 1));
                            },
                            onLeft: () {
                              viewModel.move(const Offset(-1, 0));
                            },
                            onRight: () {
                              viewModel.move(const Offset(1, 0));
                            },
                            onUp: () {
                              viewModel.move(const Offset(0, -1));
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
                                        child: SizedBox(
                                          width: wpc * child.width,
                                          height: wpc * child.height,
                                          child: InkWell(
                                            onTap: () {
                                              viewModel.selected = child;
                                            },

                                            child: AbsorbPointer(absorbing: true, child: ItemWidgetBuilder(item: child)),
                                          ),
                                        ),
                                      ),

                                    if (viewModel.selected != null)
                                      _ActiveControlWidget(
                                        active: viewModel.selected!,
                                        widthPerCell: wpc,
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
            ),
          ),
          Expanded(
            child: Consumer<PbcViewmodel>(
              builder: (BuildContext context, PbcViewmodel viewModel, Widget? child) {
                final PBItem? selected = viewModel.selected;
                if (selected == null) return const SizedBox();
                final Map<String, dynamic>? selectedParams = viewModel.selected?.param.toMap();
                return ListView(
                  key: ValueKey<PBItem?>(selected),
                  padding: const EdgeInsets.all(8),
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            const JsonEncoder encoder = JsonEncoder.withIndent('  ');
                            return Dialog(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: SelectableText(encoder.convert(viewModel.currentJson)),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.share),
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        const Text("X"),
                        Expanded(
                          child: TextFormField(
                            initialValue: selected.x.toString(),
                            onFieldSubmitted: (String? newValue) {
                              final Offset currentOffset = Offset(selected.x.toDouble(), selected.y.toDouble());

                              final Offset newOffset = Offset(double.tryParse(newValue ?? "") ?? selected.x.toDouble(), selected.y.toDouble());
                              viewModel.move(newOffset - currentOffset);
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        const Text("Y"),
                        Expanded(
                          child: TextFormField(
                            initialValue: selected.y.toString(),
                            onFieldSubmitted: (String? newValue) {
                              final Offset currentOffset = Offset(selected.x.toDouble(), selected.y.toDouble());

                              final Offset newOffset = Offset(selected.x.toDouble(), double.tryParse(newValue ?? "") ?? selected.y.toDouble());
                              viewModel.move(newOffset - currentOffset);
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        const Text("Width"),
                        Expanded(
                          child: TextFormField(
                            initialValue: selected.width.toString(),
                            onFieldSubmitted: (String? newValue) {
                              viewModel.resize(num.tryParse(newValue ?? "") ?? selected.width, selected.height);
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        const Text("Height"),
                        Expanded(
                          child: TextFormField(
                            initialValue: selected.height.toString(),
                            onFieldSubmitted: (String? newValue) {
                              viewModel.resize(selected.width, num.tryParse(newValue ?? "") ?? selected.height);
                            },
                          ),
                        ),
                      ],
                    ),

                    for (final String key in selectedParams?.keys ?? <String>[])
                      Row(
                        spacing: 10,
                        children: <Widget>[
                          Text(key),
                          Expanded(
                            child: TextFormField(
                              initialValue: selectedParams?[key]?.toString(),
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
          ...PbWidgets.all.map(
            (PbWidgets e) => Draggable<String>(
              data: e.type,
              feedback: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text(e.type)),
                ),
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text(e.type)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveControlWidget extends StatelessWidget {
  const _ActiveControlWidget({
    super.key,
    required this.active,
    required this.widthPerCell,
  });

  final PBItem active;
  final double widthPerCell;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        /// Main draggable container
        Positioned(
          left: active.x * widthPerCell,
          top: active.y * widthPerCell,
          child: Consumer<PbcViewmodel>(
            builder: (BuildContext context, PbcViewmodel viewModel, _) {
              return GestureDetector(
                onPanUpdate: (DragUpdateDetails details) {
                  /// dragging the full container moves it
                  viewModel.move(details.delta / widthPerCell);
                },
                child: Container(
                  width: active.width * widthPerCell,
                  height: active.height * widthPerCell,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              );
            },
          ),
        ),

        /// Drag Handles (one for each corner)
        ..._cornerHandles(context),
      ],
    );
  }

  List<Widget> _cornerHandles(BuildContext context) {
    return <Widget>[
      _buildHandle(context, Alignment.topLeft),
      _buildHandle(context, Alignment.topRight),
      _buildHandle(context, Alignment.bottomLeft),
      _buildHandle(context, Alignment.bottomRight),
    ];
  }

  Widget _buildHandle(BuildContext context, Alignment alignment) {
    return Positioned(
      left: (active.x * widthPerCell) + (alignment.x < 0 ? 0 : active.width * widthPerCell) - 6,
      top: (active.y * widthPerCell) + (alignment.y < 0 ? 0 : active.height * widthPerCell) - 6,
      child: Consumer<PbcViewmodel>(
        builder: (BuildContext context, PbcViewmodel viewModel, _) {
          return GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              final Offset delta = details.delta / widthPerCell;

              /// update width/height based on which handle user drags
              num newWidth = active.width;
              num newHeight = active.height;
              double moveX = 0;
              double moveY = 0;

              if (alignment.x < 0) {
                // dragging from LEFT -> shrink/grow width and shift x
                newWidth -= delta.dx;
                moveX += delta.dx;
              } else {
                newWidth += delta.dx;
              }

              if (alignment.y < 0) {
                // dragging from TOP -> shrink/grow height and shift y
                newHeight -= delta.dy;
                moveY += delta.dy;
              } else {
                newHeight += delta.dy;
              }

              /// clamp minimum size (optional)
              newWidth = newWidth.clamp(1, double.infinity);
              newHeight = newHeight.clamp(1, double.infinity);

              /// update model
              viewModel.resize(newWidth, newHeight);
              viewModel.move(Offset(moveX, moveY));
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
