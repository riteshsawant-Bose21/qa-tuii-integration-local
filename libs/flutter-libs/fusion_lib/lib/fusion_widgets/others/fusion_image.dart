import 'dart:io';
import 'package:flutter/material.dart';

/// A unified and reusable image widget for the Fusion design system.
///
/// The [FusionImage] widget provides a consistent way to display images
/// from different sources (network, file, or asset) with support for:
///
/// - Network images (with placeholder and error handling)
/// - File images (from local storage)
/// - Asset images (bundled with the app)
/// - Placeholder widgets while loading
/// - Custom error builders when loading fails
/// - Rounded corners with [BorderRadiusGeometry] or circular shape
/// - Configurable width, height, and [BoxFit]
///
/// ### Example usage
///
/// **Network image (rounded corners):**
/// ```dart
/// FusionImage.network(
///   "https://picsum.photos/200",
///   width: 120,
///   height: 120,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
///
/// **File image (circle):**
/// ```dart
/// FusionImage.circle(
///   file: File("/storage/emulated/0/Download/sample.png"),
///   size: 80,
/// )
/// ```
///
/// **Asset image (circle):**
/// ```dart
/// FusionImage.circle(
///   asset: "assets/images/avatar.png",
///   size: 64,
/// )
/// ```
class FusionImage extends StatelessWidget {
  /// The network image URL (only used in [FusionImage.network] or [FusionImage.circle]).
  final String? imageUrl;

  /// The file source for the image (only used in [FusionImage.file] or [FusionImage.circle]).
  final File? file;

  /// The asset path for the image (only used in [FusionImage.asset] or [FusionImage.circle]).
  final String? asset;

  /// Placeholder widget displayed while a network image is loading.
  final Widget? placeholder;

  /// Custom error builder when loading the image fails.
  ///
  /// If not provided, a default broken image icon will be shown.
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;

  /// The width of the image.
  final double? width;

  /// The height of the image.
  final double? height;

  /// Defines how the image should be inscribed into the allocated space.
  ///
  /// Defaults to [BoxFit.cover].
  final BoxFit fit;

  /// Optional border radius to apply rounded corners.
  final BorderRadiusGeometry? borderRadius;

  /// Whether the image should be circular.
  final bool isCircle;

  /// Creates a [FusionImage] that loads from a network URL.
  const FusionImage.network(
    this.imageUrl, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : file = null,
       asset = null,
       isCircle = false;

  /// Creates a [FusionImage] that loads from a local file.
  const FusionImage.file(this.file, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.borderRadius, this.placeholder, this.errorBuilder})
    : imageUrl = null,
      asset = null,
      isCircle = false;

  /// Creates a [FusionImage] that loads from an asset.
  const FusionImage.asset(this.asset, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.borderRadius, this.placeholder, this.errorBuilder})
    : file = null,
      imageUrl = null,
      isCircle = false;

  /// Creates a circular [FusionImage].
  ///
  /// Can be used with either [imageUrl], [file], or [asset].
  /// You must provide exactly **one source**.
  const FusionImage.circle({super.key, this.imageUrl, this.file, this.asset, this.placeholder, this.errorBuilder, double? size, this.fit = BoxFit.cover})
    : width = size,
      height = size,
      borderRadius = null,
      isCircle = true;

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (imageUrl != null) {
      /// Network image with loading/error handling
      image = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null,
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error, stackTrace);
          }
          return Icon(Icons.broken_image, size: height, color: Colors.grey);
        },
      );
    } else if (file != null) {
      /// File image
      image = Image.file(
        file!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error, stackTrace);
          }
          return Icon(Icons.broken_image, size: height, color: Colors.grey);
        },
      );
    } else if (asset != null) {
      /// Asset image
      image = Image.asset(
        asset!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error, stackTrace);
          }
          return Icon(Icons.broken_image, size: height, color: Colors.grey);
        },
      );
    } else {
      // Nothing provided
      image = const SizedBox();
    }

    if (isCircle) {
      return ClipOval(child: image);
    } else if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
