part of '../processing_block_customizer.dart';

class _CanvasView extends StatelessWidget {
  const _CanvasView();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1000 / 500,
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
                  child: DragTarget<Parameter>(
                    onAcceptWithDetails: (DragTargetDetails<Parameter> details) {
                      final String type = details.data.valueType;
                      // print("details.data.valueType: ${details.data.valueType}");

                      final List<PbWidgets> availableTypes =
                          switch (type) {
                            "float" => PbWidgets.floatWidgets,
                            "integer" => PbWidgets.floatWidgets,
                            "bool" => PbWidgets.boolWidgets,
                            _ => PbWidgets.all,
                          }.toList();
                      availableTypes.addAll(PbWidgets.genericWidgets);
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final Offset localOffset = renderBox.globalToLocal(details.offset);

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
                                            viewModel.addItem(pbWidget, Offset(localOffset.dx / wpc, localOffset.dy / wpc), details.data);
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
                    builder: (BuildContext context, List<Parameter?> candidateData, List<dynamic> rejectedData) {
                      return Stack(
                        children: <Widget>[
                          _BGGrid(
                            cellSize: wpc,
                          ),
                          if (viewModel.items.isEmpty)
                            Center(
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
    );
  }
}
