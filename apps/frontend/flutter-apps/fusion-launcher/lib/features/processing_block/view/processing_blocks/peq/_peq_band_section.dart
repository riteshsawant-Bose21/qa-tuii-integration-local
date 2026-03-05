part of 'peq_block.dart';

class _PeqBandSection extends StatelessWidget {
  const _PeqBandSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<PEQController>(
      builder: (BuildContext context, PEQController controller, Widget? child) {
        final List<_PEQDataPoint> tableData = controller.tableMappedData;
        return PBSection(
          type: PBSectionType.middle,
          padding: EdgeInsets.zero,
          child: ListView.builder(
            padding: const EdgeInsets.only(right: 8, left: 8),
            itemCount: tableData.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    spacing: 5,
                    children: <Widget>[
                      const SizedBox(
                        width: 25,
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "TYPE",
                          style: context.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...<String>["FREQUENCY", controller.isInBW ? "BW" : "Q", "GAIN(db)", "BYPASS"].map(
                        (String data) => Expanded(
                          child: Text(
                            data,
                            style: context.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      FusionPopupMenu<String>(
                        onSelected: (String? value) {
                          // Handle menu item selection
                          if ('reset' == value) {
                            controller.resetAllBands();
                          } else if ('delete' == value) {
                            controller.deleteAllBands();
                          }
                        },
                        matchChildWidth: false,
                        items: <String>['reset', 'delete'],
                        itemLabels: <String, String>{
                          "reset": "Reset all",
                          "delete": "Delete all",
                        },
                        child: Icon(
                          Icons.more_vert,
                          color: context.colorScheme.iconDefault,
                        ),
                      ),
                    ],
                  ),
                );
              }
              index -= 1;
              final _PEQDataPoint row = tableData[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  spacing: 5,
                  children: <Widget>[
                    Container(
                      width: 25,

                      decoration: BoxDecoration(
                        color: context.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: Text(
                          (index + 1).toString(),
                          style: context.textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 20,
                      child: PBDropdown<_BandType>(
                        hintText: "Type",
                        onChanged: (_BandType value) {
                          controller.updateBandType(index, value.value);
                        },
                        items: _BandType.values,
                        value: row.bandType.label,

                        itemBuilder: (BuildContext context, _BandType option) {
                          return Text(
                            option.label,
                            style: context.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: FusionContainer(
                        color: context.colorScheme.elevation2,
                        child: PBNumberTextField(
                          value: row.frequency,
                          onChanged: (num value) {
                            controller.updateBandFrequency(index, value);
                          },
                          min: 20,
                          max: 20000,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: DisabledWidgetWrapper(
                        isDisabled: row.isQDisabled,
                        child: FusionContainer(
                          color: context.colorScheme.elevation2,
                          child: PBNumberTextField(
                            value: row.q,
                            onChanged: (num value) {
                              controller.updateQ(index, value);
                            },
                            min: 0.1,
                            max: 10,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 13,
                      child: DisabledWidgetWrapper(
                        isDisabled: row.isGainDisabled,
                        child:
                            row.isGainDropdown
                                ? PBDropdown<_CutType>(
                                  hintText: "0.0",
                                  onChanged: (_CutType value) {
                                    controller.updateGain(index, value.value);
                                  },
                                  items: _CutType.values,
                                  value: row.cutType?.label ?? row.gain.toString(),
                                  itemBuilder: (BuildContext context, _CutType option) {
                                    return Text(
                                      option.label,
                                      style: context.textTheme.bodySmall,
                                    );
                                  },
                                )
                                : FusionContainer(
                                  color: context.colorScheme.elevation2,
                                  child: PBNumberTextField(
                                    value: row.gain,
                                    onChanged: (num value) {
                                      controller.updateGain(index, value);
                                    },
                                    min: -24,
                                    max: 24,
                                  ),
                                ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: FusionSwitch(
                        value: row.bypass,
                        inactiveTrackColor: context.colorScheme.elevation2,
                        inactiveThumbColor: context.colorScheme.elevation3,

                        width: 60,
                        height: 35,
                        onChanged: (bool value) {
                          controller.updateBypass(index, value);
                        },
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        controller.removeBand(index);
                      },
                      child: Icon(
                        LucideIcons.trash200,
                        size: 16,
                        color: controller.canDelete ? context.colorScheme.iconDefault : context.colorScheme.iconDisabled,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
