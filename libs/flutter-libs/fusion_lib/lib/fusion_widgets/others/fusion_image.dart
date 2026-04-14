import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A smart image widget that auto-detects the image source.
///
/// ### Source detection order
/// 1. [bytes] is provided          → [Image.memory]
/// 2. [path] is null or empty      → shows [fallbackIcon] immediately
/// 3. Starts with `http(s)://`     → [Image.network]
/// 4. Exists on disk               → [Image.file]
/// 5. Otherwise                    → [Image.asset]
class FusionImageAuto extends StatelessWidget {
  /// Raw image bytes — takes priority over [path].
  final Uint8List? bytes;

  /// The image path — URL, absolute file path, or asset path.
  /// Pass null to show [fallbackIcon] immediately.
  final String? path;

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final bool isCircle;
  final Color? color;

  /// Widget to show while a network image is loading.
  final Widget? placeholder;

  /// Icon/widget shown when no source is available or load fails.
  final Widget? fallbackIcon;

  /// Custom error builder — overrides [fallbackIcon] when provided.
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  final String? semanticId;
  final String? semanticLabel;

  const FusionImageAuto({
    super.key,
    this.bytes,
    this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.color,
    this.placeholder,
    this.fallbackIcon,
    this.errorBuilder,
    this.semanticId,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _applyClip(_buildImage(context));
  }

  // ── source resolution ─────────────────────────────────────────────────────

  Widget _buildImage(BuildContext context) {
    // 1. Memory bytes — highest priority
    if (bytes != null && bytes!.isNotEmpty) {
      return _memory(context, bytes!);
    }

    final String? resolvedPath = path?.trim();

    // 2. No path → fallback
    if (resolvedPath == null || resolvedPath.isEmpty) {
      return _fallback(context);
    }

    // 3. Network
    if (resolvedPath.startsWith('http://') || resolvedPath.startsWith('https://')) {
      return _network(context, resolvedPath);
    }

    // 4. Local file
    if (File(resolvedPath).existsSync()) {
      return _file(context, File(resolvedPath));
    }

    // 5. Asset
    return _asset(context, resolvedPath);
  }

  // ── per-source builders ───────────────────────────────────────────────────

  Widget _memory(BuildContext context, Uint8List data) {
    return _wrap(
      Image.memory(
        data,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (ctx, err, st) => errorBuilder?.call(ctx, err, st) ?? _fallback(ctx),
      ),
    );
  }

  Widget _network(BuildContext context, String url) {
    return _wrap(
      Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        color: color,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              SizedBox(
                width: width,
                height: height,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null,
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (ctx, err, st) => errorBuilder?.call(ctx, err, st) ?? _fallback(ctx),
      ),
    );
  }

  Widget _file(BuildContext context, File f) {
    return _wrap(
      Image.file(
        f,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (ctx, err, st) => errorBuilder?.call(ctx, err, st) ?? _fallback(ctx),
      ),
    );
  }

  Widget _asset(BuildContext context, String assetPath) {
    return _wrap(
      Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (ctx, err, st) => errorBuilder?.call(ctx, err, st) ?? _fallback(ctx),
      ),
    );
  }

  // ── fallback ──────────────────────────────────────────────────────────────

  Widget _fallback(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child:
            fallbackIcon ??
            Icon(
              LucideIcons.imageOff200,
              size: 16,
              color: context.colorScheme.iconDefault,
            ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Widget _wrap(Widget child) {
    if (semanticId == null && semanticLabel == null) return child;
    return SemanticHelper.image(
      testId: SemanticHelper.createTestId(
        SemanticTypes.icon,
        'fusion_image_auto_$semanticId',
      ),
      label: semanticLabel,
      child: child,
    );
  }

  Widget _applyClip(Widget image) {
    if (isCircle) return ClipOval(child: image);
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
