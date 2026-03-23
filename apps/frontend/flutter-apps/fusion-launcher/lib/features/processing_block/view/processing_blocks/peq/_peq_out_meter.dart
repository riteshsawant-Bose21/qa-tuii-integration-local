part of 'peq_block.dart';

class _PeqOutMeter extends StatelessWidget {
  const _PeqOutMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return PBSection(
      semanticId: 'peq_out_meter',
      type: PBSectionType.right,
      child: Column(
        spacing: 10,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colorScheme.elevation3,
                  width: 1,
                ),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: FusionAppText(
                text: "OUTPUT",
              ),
            ),
          ),
          const Expanded(
            child: VerticalMeter(
              semanticId: 'peq_out_meter_vertical_meter',
              value: -60,
              min: -60,
              max: 0,
            ),
          ),
        ],
      ),
    );
  }
}
