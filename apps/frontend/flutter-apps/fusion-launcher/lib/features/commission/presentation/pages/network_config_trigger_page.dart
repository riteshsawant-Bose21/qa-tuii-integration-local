import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../widgets/configure_network_dialog.dart';

// Import your dialog file
// import 'configure_network_dialog.dart';

class NetworkConfigTrigger extends StatefulWidget {
  /// If true, the dialog will only appear once per "Session" (Widget lifecycle).
  /// If false, it could reappear if the user scrolls away and comes back.
  final bool triggerOnce;

  const NetworkConfigTrigger({
    super.key,
    this.triggerOnce = true,
  });

  @override
  State<NetworkConfigTrigger> createState() => _NetworkConfigTriggerState();
}

class _NetworkConfigTriggerState extends State<NetworkConfigTrigger> {
  // Global tracker to ensure only one instance of this dialog exists app-wide
  static bool _isDialogActive = false;

  // Local tracker to prevent re-triggering if the user dismisses it
  // (unless the widget is rebuilt or scrolled away and back, depending on logic)
  bool _hasTriggered = false;

  void _showDialogIfNeeded() async {
    // 1. Edge Case: Dialog is already open anywhere in the app
    if (_isDialogActive) return;

    // 2. Edge Case: Widget has already performed its duty (optional safety)
    if (widget.triggerOnce && _hasTriggered) return;

    // 3. Edge Case: Widget is unmounted before the check completes
    if (!mounted) return;

    // Lock the dialog state
    _isDialogActive = true;
    _hasTriggered = true;

    try {
      // 4. Edge Case: Ensure context is valid before showing
      if (mounted) {
        await ConfigureNetworkDialog.show(context);
      }
    } finally {
      // 5. Edge Case: Always unlock, even if the dialog crashes or is dismissed
      _isDialogActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('network-config-trigger'),
      onVisibilityChanged: (VisibilityInfo info) {
        // Trigger only if more than 50% of the widget is visible
        if (info.visibleFraction > 0.5) {
          _showDialogIfNeeded();
        }
      },
      child: Container(),
    );
  }
}
