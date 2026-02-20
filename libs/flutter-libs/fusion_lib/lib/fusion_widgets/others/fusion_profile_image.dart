import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

/// A reusable widget for displaying a profile image clipped into an oval.
///
/// Supports network, asset, and file images with optional placeholder,
/// border, and size control.
///
/// Example usage:
/// ```dart
/// // 1. Network image
/// FusionProfileImage(
///   imageUrl: 'https://example.com/profile.jpg',
///   size: 60,
/// ),
///
/// // 2. Asset image with border
/// FusionProfileImage.asset(
///   'assets/images/avatar.png',
///   size: 50,
///   border: Border.all(color: Colors.blue, width: 2),
/// ),
///
/// // 3. File image with placeholder
/// FusionProfileImage.file(
///   File('/path/to/image.jpg'),
///   size: 70,
///   placeholder: Icon(Icons.person, size: 40),
/// ),
/// ```
class FusionProfileImage extends StatelessWidget {
  final String? semanticId;
  final double size;
  final BoxBorder? border;
  final Widget? placeholder;
  final String? imageUrl;
  final String? assetPath;
  final File? file;

  const FusionProfileImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.file,
    this.size = 50,
    this.border,
    this.placeholder,
    this.semanticId,
  });

  /// Named constructor for asset image
  const FusionProfileImage.asset(
    this.assetPath, {
    super.key,
    this.size = 50,
    this.border,
    this.placeholder,
    this.semanticId,
  }) : imageUrl = null,
       file = null;

  /// Named constructor for file image
  const FusionProfileImage.file(
    this.file, {
    super.key,
    this.size = 50,
    this.border,
    this.placeholder,
    this.semanticId,
  }) : imageUrl = null,
       assetPath = null;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl != null) {
      imageWidget = ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SemanticHelper.container(
              testId: SemanticHelper.createTestId(
                SemanticTypes.section,
                "fusion_profile_image_${semanticId ?? ""}",
              ),
              child: _buildPlaceholder(),
            );
          },
        ),
      );
    } else if (assetPath != null) {
      imageWidget = ClipOval(
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (file != null) {
      imageWidget = ClipOval(
        child: Image.file(
          file!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    } else {
      imageWidget = ClipOval(child: _buildPlaceholder());
    }

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.section,
        "fusion_profile_image_${semanticId ?? ""}",
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: imageWidget,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          color: Colors.grey.shade300,
          child: Icon(
            Icons.person,
            size: size * 0.6,
            color: Colors.grey.shade600,
          ),
        );
  }
}
