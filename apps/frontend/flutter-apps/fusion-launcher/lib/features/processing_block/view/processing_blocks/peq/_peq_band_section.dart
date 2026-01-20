part of 'peq_block.dart';

class _PeqBandSection extends StatelessWidget {
  const _PeqBandSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<PEQController>(
      builder: (BuildContext context, PEQController controller, Widget? child) {
        final List<({num frequency, num gain, num q, String type, bool bypass})> tableData = controller.tableMappedData;
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
          ),
          padding: const EdgeInsets.only(right: 8),
          child: ListView.builder(
            itemCount: tableData.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    spacing: 8,
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Text(
                          "TYPE",
                          style: context.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...<String>["FREQUENCY", "Q", "GAIN", "BYPASS"].map(
                        (String data) => Expanded(
                          child: Text(
                            data,
                            style: context.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Opacity(opacity: 0, child: Icon(Icons.delete, color: context.colorScheme.error)),
                    ],
                  ),
                );
              }
              index -= 1;
              return Row(
                spacing: 8,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: PBDropdown<String>(
                      hintText: "Type",
                      onChanged: (String value) {
                        controller.updateBandType(index, value);
                      },
                      value: tableData[index].type.titleCase,
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          ...<String>["peq", "high_shelf", "low_shelf", "hpf", "lpf", "notch"].map(
                            (String type) => PopupMenuItem<String>(
                              value: type.titleCase,
                              child: Text(type.titleCase),
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                  Expanded(
                    child: FusionContainer(
                      color: context.colorScheme.elevation2,
                      child: PBNumberTextField(
                        value: tableData[index].frequency,
                        onChanged: (num value) {
                          controller.updateBandFrequency(index, value);
                        },
                        min: 20,
                        max: 20000,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FusionContainer(
                      color: context.colorScheme.elevation2,
                      child: PBNumberTextField(
                        value: tableData[index].q,
                        onChanged: (num value) {
                          controller.updateQ(index, value);
                        },
                        min: 0.1,
                        max: 10,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FusionContainer(
                      color: context.colorScheme.elevation2,
                      child: PBNumberTextField(
                        value: tableData[index].gain,
                        onChanged: (num value) {
                          controller.updateGain(index, value);
                        },
                        min: -24,
                        max: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FusionSwitch(
                        value: tableData[index].bypass,
                        inactiveTrackColor: context.colorScheme.elevation2,
                        inactiveThumbColor: context.colorScheme.elevation3,
                        width: 60,
                        height: 35,
                        onChanged: (bool value) {
                          controller.updateBypass(index, value);
                        },
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      controller.removeBand(index);
                    },
                    child: Icon(
                      Icons.delete_outline,
                      color: controller.canDelete ? context.colorScheme.iconDefault : context.colorScheme.iconDisabled,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
