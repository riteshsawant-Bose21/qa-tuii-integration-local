part of '../processing_block_customizer.dart';

class _PBCItemList extends StatelessWidget {
  const _PBCItemList();

  @override
  Widget build(BuildContext context) {
    final PbcViewmodel viewModel = context.watch<PbcViewmodel>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Text(
            "Available Fields",
            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(
            height: 10,
          ),
          ...(viewModel.algorithm.parameters ?? <Parameter>[]).map(
            (Parameter e) {
              final Iterable<PBItem> where = viewModel.items.where((PBItem item) => item.field == e.name);
              final bool isAdded = where.isNotEmpty;
              final bool isSelected = viewModel.selected != null && viewModel.selected!.field == e.name;
              if (isAdded) {
                return InkWell(
                  onTap: () {
                    viewModel.selected = where.first;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration:
                        isSelected
                            ? BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                            )
                            : BoxDecoration(
                              color: Colors.grey.shade300,
                            ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(e.name)),
                    ),
                  ),
                );
              }
              return Draggable<_PBItemWrapper>(
                data: _PBItemWrapper(telemetry: null, parameter: e),
                feedback: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(e.name)),
                  ),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(e.name)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            "Available Telemetries",
            style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(
            height: 10,
          ),
          ...(viewModel.algorithm.telemetry ?? <Telemetry>[]).map(
            (Telemetry e) {
              final Iterable<PBItem> where = viewModel.items.where((PBItem item) => item.field == e.name);
              final bool isAdded = where.isNotEmpty;
              final bool isSelected = viewModel.selected != null && viewModel.selected!.field == e.name;
              if (isAdded) {
                return InkWell(
                  onTap: () {
                    viewModel.selected = where.first;
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration:
                        isSelected
                            ? BoxDecoration(
                              border: Border.all(color: Colors.black, width: 2),
                            )
                            : BoxDecoration(
                              color: Colors.grey.shade300,
                            ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(e.name)),
                    ),
                  ),
                );
              }
              return Draggable<_PBItemWrapper>(
                data: _PBItemWrapper(telemetry: e, parameter: null),
                feedback: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(e.name)),
                  ),
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(e.name)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
