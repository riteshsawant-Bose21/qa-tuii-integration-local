part of 'peq_block.dart';

class PeqGraph extends StatelessWidget {
  const PeqGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(context.mediumRadius),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          const Expanded(child: Center()),
          FusionButton(
            label: "Add Band",
            onTap: () {
              context.read<PEQController>().addBand();
            },
          ),
        ],
      ),
    );
  }
}
