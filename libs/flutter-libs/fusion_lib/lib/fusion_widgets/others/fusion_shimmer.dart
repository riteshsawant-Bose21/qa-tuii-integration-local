import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable shimmer loading widget for the Fusion design system.
///
/// The [FusionShimmer] can be used to display a shimmer animation
/// as a placeholder while content is loading.
///
/// It supports:
/// - Custom width, height, and border radius
/// - A fully custom shimmer child widget
/// - Default shimmer placeholder container
/// - Customizable shimmer colors
///
/// ### Example usage:
/// ```dart
/// FusionShimmer(
///   width: 120,
///   height: 20,
///   radius: 8,
/// )
///
/// FusionShimmer(
///   customisedShimmerLoader: true,
///   customisedShimmerWidget: CircleAvatar(radius: 30),
/// )
/// ```
class FusionShimmer extends StatelessWidget {
  /// Width of the shimmer widget. Default is 50.
  final double width;

  /// Height of the shimmer widget. Default is 12.
  final double height;

  /// Border radius of the shimmer container. Default is 4.
  final double radius;

  /// Whether to use a custom shimmer widget.
  final bool customisedShimmerLoader;

  /// A fully custom widget to be wrapped in shimmer effect.
  final Widget? customisedShimmerWidget;

  /// Base color of the shimmer. Default is `Colors.grey.shade300`.
  final Color baseColor;

  /// Highlight color of the shimmer. Default is `Colors.grey.shade100`.
  final Color highlightColor;

  final String? semanticId;

  /// Creates a [FusionShimmer].
  const FusionShimmer({
    super.key,
    this.semanticId,
    this.width = 50.0,
    this.height = 12.0,
    this.radius = 4.0,
    this.customisedShimmerLoader = false,
    this.customisedShimmerWidget,
    this.baseColor = const Color(0xFFD6D6D6),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.card,
        "fusion_shimmer${semanticId ?? ""}",
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: customisedShimmerLoader && customisedShimmerWidget != null
            ? customisedShimmerWidget!
            : Container(
                margin: const EdgeInsets.only(top: 5),
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
      ),
    );
  }
}
