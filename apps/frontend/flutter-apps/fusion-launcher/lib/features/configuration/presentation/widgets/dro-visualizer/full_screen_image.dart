import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:typed_data';

class FullScreenImagePage extends StatelessWidget {
  final Uint8List imageBytes;

  const FullScreenImagePage({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: PhotoView(
                imageProvider: MemoryImage(imageBytes),
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.contained * 4.0,
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
