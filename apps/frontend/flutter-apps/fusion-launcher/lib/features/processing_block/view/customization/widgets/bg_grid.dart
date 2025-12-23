part of '../processing_block_customizer.dart';

class _BGGrid extends StatelessWidget {
  const _BGGrid({required this.cellSize});
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        final double totalHeight = constraints.maxHeight;
        final int horizontalLines = (totalWidth / cellSize).ceil() + 1;
        final int verticalLines = (totalHeight / cellSize).ceil() + 1;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (int i = 0; i <= horizontalLines; i++) ...<Widget>[
              if (i % 10 == 0)
                Positioned(
                  left: i * cellSize,
                  top: -20,
                  child: Text(
                    i.toString(),
                    style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10),
                  ),
                ),
              Positioned(
                left: i * cellSize,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: i % 10 == 0 ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
                ),
              ),
            ],
            for (int j = 0; j <= verticalLines; j++)
              Positioned(
                top: j * cellSize,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  color: j % 10 == 0 ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
                ),
              ),
          ],
        );
      },
    );
  }
}
