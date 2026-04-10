import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A smart image widget that auto-detects the image source from a single [path].
///
/// ### Source detection order
/// 1. [path] is null or empty     → shows [fallbackIcon] immediately
/// 2. Starts with `http(s)://`    → [Image.network]
/// 3. Exists on disk              → [Image.file]
/// 4. Otherwise                   → [Image.asset]
class FusionImageAuto extends StatelessWidget {
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

  /// Icon/widget shown when [path] is null, file is missing, or load fails.
  /// Defaults to [Icons.broken_image] at [errorIconSize].
  final Widget? fallbackIcon;

  /// Size of the default broken-image icon. Ignored when [fallbackIcon] is set.
  final double errorIconSize;

  /// Custom error builder — overrides [fallbackIcon] when provided.
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  final String? semanticId;
  final String? semanticLabel;

  const FusionImageAuto({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircle = false,
    this.color,
    this.placeholder,
    this.fallbackIcon,
    this.errorIconSize = 24,
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
    final String? resolvedPath = path?.trim();

    if (resolvedPath == null || resolvedPath.isEmpty) return _fallback(context);
    if (resolvedPath.startsWith('http://') || resolvedPath.startsWith('https://')) return _network(context, resolvedPath);
    if (File(resolvedPath).existsSync()) return _file(context, File(resolvedPath));
    return _asset(context, resolvedPath);
  }

  // ── per-source builders ───────────────────────────────────────────────────

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
              size: errorIconSize,
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
