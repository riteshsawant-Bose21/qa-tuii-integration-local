import 'package:flutter/material.dart';
import 'enhanced_amplifier_matching_widget.dart';

/// Amplifier Suggestion Widget
/// 
/// This widget provides an enhanced UI for amplifier matching with:
/// - 70V/100V voltage selection
/// - Circuit import functionality  
/// - Side-by-side symmetrical vs asymmetrical comparison
/// - Catalog-based amplifier recommendations
class AmpSuggestionWidget extends StatelessWidget {
  const AmpSuggestionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedAmplifierMatchingWidget();
  }
}