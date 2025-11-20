// ignore_for_file: public_member_api_docs, sort_constructors_first
part of '../processing_block_customizer.dart';

class _CanvasView extends StatelessWidget {
  const _CanvasView();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: AspectRatio(
          aspectRatio: 1000 / 500,
          child: Container(
            color: Colors.white,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double wpc = constraints.maxHeight / 100;
                return Consumer<PbcViewmodel>(
                  builder: (BuildContext context, PbcViewmodel viewModel, Widget? child) {
                    return Scrollbar(
                      controller: viewModel.scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: viewModel.scrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: SizedBox(
                          width: (wpc * viewModel.width) + wpc * 20,
                          height: wpc * 100,
                          child: FusionKeyboardWrapper(
                            onDelete: () {
                              viewModel.delete();
                            },
                            onShiftDown: () {
                              viewModel.isShiftPressed = true;
                            },
                            onShiftUp: () {
                              viewModel.isShiftPressed = false;
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
                            child: DragTarget<_PBItemWrapper>(
                              onAcceptWithDetails: (DragTargetDetails<_PBItemWrapper> details) {
                                final String type = details.data.parameter?.valueType ?? details.data.telemetry?.valueType ?? "";

                                final List<PbWidgets> availableTypes =
                                    switch (type) {
                                      "float" => PbWidgets.floatWidgets,
                                      "integer" => PbWidgets.floatWidgets,
                                      "bool" => PbWidgets.boolWidgets,
                                      "string" => <PbWidgets>[],
                                      _ => PbWidgets.all,
                                    }.toList();
                                if (details.data.parameter != null && (details.data.parameter?.allowedValues?.isNotEmpty ?? false)) {
                                  availableTypes.addAll(PbWidgets.selectWidgets);
                                }
                                availableTypes.addAll(PbWidgets.genericWidgets);
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final Offset localOffset = renderBox.globalToLocal(details.offset) + Offset(viewModel.scrollController.offset, 0);

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            FusionAppText(
                                              text: "Select How do you want to represent '${details.data.name}'",
                                              style: context.textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 20),
                                            Wrap(
                                              spacing: 10,
                                              // shrinkWrap: true,
                                              // gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 100),
                                              // itemCount: availableTypes.length,
                                              // itemBuilder: (BuildContext context, int index) {
                                              children: <Widget>[
                                                for (final PbWidgets pbWidget in availableTypes)
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.of(context).pop();
                                                      if (details.data.parameter != null) {
                                                        viewModel.addParameter(
                                                          pbWidget,
                                                          Offset(localOffset.dx / wpc, localOffset.dy / wpc),
                                                          details.data.parameter!,
                                                        );
                                                      } else if (details.data.telemetry != null) {
                                                        viewModel.addTelemetry(
                                                          pbWidget,
                                                          Offset(localOffset.dx / wpc, localOffset.dy / wpc),
                                                          details.data.telemetry!,
                                                        );
                                                      }
                                                    },
                                                    child: SizedBox(
                                                      height: 100,
                                                      width: 100,
                                                      child: Card(
                                                        child: AspectRatio(
                                                          aspectRatio: 1,
                                                          child: Center(child: FusionAppText(text: pbWidget.type.titleCase)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                              // },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              builder: (BuildContext context, List<_PBItemWrapper?> candidateData, List<dynamic> rejectedData) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    Container(
                                      clipBehavior: Clip.none,
                                      width: wpc * viewModel.width,
                                      // height: wpc * 100,
                                      child: _BGGrid(
                                        cellSize: wpc,
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: wpc * (200),

                                      child: Container(
                                        width: wpc * (viewModel.width - 200),
                                        height: wpc * 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: wpc * (viewModel.width + 2),
                                      top: 0,
                                      child: InkWell(
                                        onTap: () {
                                          viewModel.addExtraWidth();
                                        },
                                        child: Container(
                                          width: wpc * 16,
                                          height: wpc * 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.grey.withOpacity(0.1),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.add,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (viewModel.items.isEmpty)
                                      SizedBox(
                                        width: wpc * viewModel.width,
                                        height: wpc * 100,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                Icons.info,
                                                size: 50,
                                                color: Colors.grey.shade300,
                                              ),
                                              Text(
                                                "Drag and Drop fields from 'Available Fields' to here.",
                                                style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    for (final PBItem child in viewModel.items)
                                      Positioned(
                                        left: wpc * child.x,
                                        top: wpc * child.y,
                                        child: SizedBox(
                                          width: wpc * child.width,
                                          height: wpc * child.height,
                                          child: InkWell(
                                            onTap: () {
                                              viewModel.setSelected(child);
                                            },
                                            child: AbsorbPointer(absorbing: true, child: ItemWidgetBuilder(item: child)),
                                          ),
                                        ),
                                      ),

                                    // if (viewModel.selected != null)
                                    for (final PBItem selected in viewModel.selectedItems)
                                      _ActiveControlWidget(
                                        active: selected,
                                        widthPerCell: wpc,
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PBItemWrapper {
  final Parameter? parameter;
  final Telemetry? telemetry;

  _PBItemWrapper({required this.parameter, required this.telemetry});

  @override
  bool operator ==(covariant _PBItemWrapper other) {
    if (identical(this, other)) return true;

    return other.parameter == parameter && other.telemetry == telemetry;
  }

  @override
  int get hashCode => parameter.hashCode ^ telemetry.hashCode;

  String get name => parameter?.name ?? telemetry?.name ?? "";
}
