import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConnectionPainter extends CustomPainter {
  final Map<String, List<Offset>> centersById;
  ConnectionPainter(this.centersById);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2;
    centersById.forEach((String id, List<Offset> centers) {
      for (int i = 0; i < centers.length - 1; i++) {
        canvas.drawLine(centers[i], centers[i + 1], paint);
      }
    });
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter old) => !mapEquals(old.centersById, centersById);
}
