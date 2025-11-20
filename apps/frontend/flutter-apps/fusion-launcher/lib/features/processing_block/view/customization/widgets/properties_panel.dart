part of '../processing_block_customizer.dart';

class _PropertiesPanel extends StatelessWidget {
  const _PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade400)), color: Colors.white),
      child: Consumer<PbcViewmodel>(
        builder: (BuildContext context, PbcViewmodel viewModel, Widget? child) {
          final PBItem? selected = viewModel.selected;
          if (selected == null) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  const Icon(
                    Icons.info_outline,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Please select an item from the canvas to view and edit its properties.",
                    style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final Map<String, dynamic>? selectedParams = viewModel.selected?.param.toMap();
          return ListView(
            key: ValueKey<PBItem?>(selected),
            padding: const EdgeInsets.all(8),
            children: <Widget>[
              Text(
                "Properties",
                style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(
                height: 10,
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
              const SizedBox(
                height: 20,
              ),
              FusionButton(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
                      return Dialog(
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 500),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 20,
                              children: <Widget>[
                                Row(
                                  spacing: 40,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text("Current Configuration JSON", style: context.textTheme.titleLarge),

                                    IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Container(
                                    color: Colors.grey.shade300,
                                    padding: const EdgeInsets.all(10.0),
                                    child: SelectableText(encoder.convert(viewModel.currentJson)),
                                  ),
                                ),
                                FusionButton(
                                  label: "Save this Configuration",
                                  width: 250,
                                  onTap: () {
                                    ///
                                    /// Save the configuration JSON to a file
                                    ///
                                    FilePicker.platform
                                        .saveFile(
                                          dialogTitle: 'Save Configuration JSON',
                                          fileName: '${viewModel.algorithm.name}.json',
                                          type: FileType.custom,
                                          allowedExtensions: <String>['json'],
                                        )
                                        .then((String? path) {
                                          if (path != null) {
                                            final File file = File(path);
                                            file.writeAsStringSync(jsonEncode(viewModel.currentJson));
                                            Navigator.of(context).pop();
                                          }
                                        });
                                  },
                                ),
                                FusionButton(
                                  label: "Save In App",
                                  width: 250,
                                  onTap: () async {
                                    ///
                                    /// Save the configuration JSON to a file
                                    ///
                                    await viewModel.saveLayout();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                label: "View layout JSON",
                // style: context.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}
