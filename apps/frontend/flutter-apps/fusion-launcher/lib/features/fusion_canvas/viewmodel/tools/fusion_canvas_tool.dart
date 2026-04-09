import 'package:fusion_launcher/features/fusion_canvas/state/fusion_tool_state.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/connection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/state/tools/selection_tool_params.dart';
import 'package:fusion_launcher/features/fusion_canvas/viewmodel/fusion_canvas_tool_viewmodel.dart';

import '../../state/fusion_canvas_input_state.dart';
import '../../state/tools/drag_tool_state.dart';
import '../../state/tools/measure_tool_state.dart';
import '../../state/tools/pen_tool_state.dart';
import '../../state/tools/select_tool_state.dart';
import '../tool_helper/connection_tool_helper.dart';
import '../tool_helper/drag_tool_helper.dart';
import '../tool_helper/measure_tool_helper.dart';
import '../tool_helper/pen_tool_helper.dart';
import '../tool_helper/selection_tool_helper.dart';

class FusionCanvasTool<T extends FusionToolState> {
  static const FusionCanvasTool<MeasureToolState> measureTool = FusionCanvasTool<MeasureToolState>(transformer: MeasureToolHelper());
  static const FusionCanvasTool<PenToolState> penTool = FusionCanvasTool<PenToolState>(transformer: PenToolHelper());
  static const FusionCanvasTool<DragToolState> dragTool = FusionCanvasTool<DragToolState>(transformer: DragToolHelper());
  static const FusionCanvasTool<SelectToolState> singleSelectionTool = FusionCanvasTool<SelectToolState>(
    transformer: SelectionToolHelper(
      selectionToolParams: SelectionToolParams(
        enableSelect: true,
        enableMultiSelect: false,
        enableMarqueeSelection: false,
      ),
    ),
  );
  static const FusionCanvasTool<SelectToolState> multiSelectionTool = FusionCanvasTool<SelectToolState>(
    transformer: SelectionToolHelper(
      selectionToolParams: SelectionToolParams(
        enableSelect: true,
        enableMultiSelect: true,
        enableMarqueeSelection: true,
      ),
    ),
  );

  /// A combined selection + connection tool.
  ///
  /// Behaves like a normal selection tool but intercepts drag gestures that
  /// start on a [WiringPortData] to draw an orthogonal wiring connection.
  /// When the user releases the pointer, [ConnectionToolParams.onConnectionDrop]
  /// is called with the source port, drop position, and optional destination port.
  ///
  /// Replace [multiSelectionTool] / [singleSelectionTool] with this in your
  /// [FusionCanvas.tools] list to enable wiring connections:
  ///
  /// ```dart
  /// tools: [
  ///   FusionCanvasTool.measureTool,
  ///   FusionCanvasTool.penTool,
  ///   FusionCanvasTool.dragTool,
  ///   FusionCanvasTool.connectionTool(
  ///     connectionParams: ConnectionToolParams(
  ///       onConnectionDrop: (source, pos, dest) { /* handle */ },
  ///     ),
  ///   ),
  /// ]
  /// ```
  static FusionCanvasTool<SelectToolState> connectionTool({
    required ConnectionToolParams connectionParams,
    SelectionToolParams selectionParams = const SelectionToolParams(
      enableSelect: true,
      enableMultiSelect: true,
      enableMarqueeSelection: true,
    ),
  }) => FusionCanvasTool<SelectToolState>(
    transformer: ConnectionToolHelper(
      connectionParams: connectionParams,
      selectionParams: selectionParams,
    ),
  );

  bool canHandleState(FusionToolState state) => state is T;

  final FusionCanvasToolTransformer<T> transformer;

  const FusionCanvasTool({required this.transformer});
}

abstract class FusionCanvasToolTransformer<T extends FusionToolState> {
  const FusionCanvasToolTransformer();
  FusionToolState transform({
    required FusionCanvasInputState inputState,
    required FusionCanvasInputContext context,
    required T currentState,
  });
}
