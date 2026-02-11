import 'package:flutter/cupertino.dart';

class DisabledWidgetWrapper extends StatelessWidget {
  const DisabledWidgetWrapper({
    super.key,
    required this.child,
    required this.isDisabled,
  });
  final Widget child;
  final bool isDisabled;
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: isDisabled,
        child: child,
      ),
    );
  }
}
