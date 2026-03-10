part of '../processing_block_customizer.dart';

class _ActiveControlWidget extends StatelessWidget {
  const _ActiveControlWidget({
    required this.active,
    required this.widthPerCell,
  });

  final PBItem active;
  final double widthPerCell;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(
        SemanticTypes.button,
        "active_control_widget",
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: active.x * widthPerCell,
            top: active.y * widthPerCell,
            child: Consumer<PbcViewmodel>(
              builder: (BuildContext context, PbcViewmodel viewModel, _) {
                return GestureDetector(
                  onPanUpdate: (DragUpdateDetails details) {
                    /// dragging the full container moves it
                    viewModel.move(details.delta / widthPerCell);
                  },
                  child: Container(
                    width: active.width * widthPerCell,
                    height: active.height * widthPerCell,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                  ),
                );
              },
            ),
          ),

          /// Drag Handles (one for each corner)
          ..._cornerHandles(context),
        ],
      ),
    );
  }

  List<Widget> _cornerHandles(BuildContext context) {
    return <Widget>[
      _buildHandle(context, Alignment.topLeft),
      _buildHandle(context, Alignment.topRight),
      _buildHandle(context, Alignment.bottomLeft),
      _buildHandle(context, Alignment.bottomRight),
    ];
  }

  Widget _buildHandle(BuildContext context, Alignment alignment) {
    return Positioned(
      left:
          (active.x * widthPerCell) +
          (alignment.x < 0 ? 0 : active.width * widthPerCell) -
          6,
      top:
          (active.y * widthPerCell) +
          (alignment.y < 0 ? 0 : active.height * widthPerCell) -
          6,
      child: Consumer<PbcViewmodel>(
        builder: (BuildContext context, PbcViewmodel viewModel, _) {
          return GestureDetector(
            onPanUpdate: (DragUpdateDetails details) {
              final Offset delta = details.delta / widthPerCell;

              /// update width/height based on which handle user drags
              num newWidth = active.width;
              num newHeight = active.height;
              double moveX = 0;
              double moveY = 0;

              if (alignment.x < 0) {
                // dragging from LEFT -> shrink/grow width and shift x
                newWidth -= delta.dx;
                moveX += delta.dx;
              } else {
                newWidth += delta.dx;
              }

              if (alignment.y < 0) {
                // dragging from TOP -> shrink/grow height and shift y
                newHeight -= delta.dy;
                moveY += delta.dy;
              } else {
                newHeight += delta.dy;
              }

              /// clamp minimum size (optional)
              newWidth = newWidth.clamp(1, double.infinity);
              newHeight = newHeight.clamp(1, double.infinity);

              /// update model
              viewModel.resize(newWidth, newHeight);
              viewModel.move(Offset(moveX, moveY));
            },
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
    );
  }
}
