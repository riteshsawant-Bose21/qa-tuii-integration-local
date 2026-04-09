import 'fusion_canvas_element.dart';

class FusionCanvasItem extends FusionCanvasElement {
  @override
  final String id;
  
  FusionCanvasItem({
    required this.id,
  });

  @override
  List<String> get pointIds => [];
}
