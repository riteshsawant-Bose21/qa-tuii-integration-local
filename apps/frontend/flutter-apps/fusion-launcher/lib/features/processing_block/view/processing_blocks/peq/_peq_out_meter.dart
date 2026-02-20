part of 'peq_block.dart';

class _PeqOutMeter extends StatelessWidget {
  const _PeqOutMeter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(context.mediumRadius),
        ),
      ),
      padding: const EdgeInsets.all(8),
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
