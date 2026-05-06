import 'package:flutter/cupertino.dart';

class DisabledWidgetWrapper extends StatelessWidget {
  const DisabledWidgetWrapper({
    super.key,
    required this.child,
    required this.isDisabled,
  });

  final Widget child;
  final bool isDisabled;

  static DisabledWidgetScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DisabledWidgetScope>();
  }

  static DisabledWidgetScope of(BuildContext context) {
    final DisabledWidgetScope? wrapper = maybeOf(context);
    assert(wrapper != null, 'No DisabledWidgetWrapper found in context.');
    return wrapper!;
  }

  @override
  Widget build(BuildContext context) {
    final bool parentDisabled = maybeOf(context)?.isDisabled ?? false;
    final bool effectiveIsDisabled = parentDisabled || isDisabled;

    return DisabledWidgetScope(
      isDisabled: effectiveIsDisabled,
      child: _DisabledWidgetEffects(
        isDisabled: effectiveIsDisabled,
        child: child,
      ),
    );
  }
}

class DisabledWidgetScope extends InheritedWidget {
  const DisabledWidgetScope({
    super.key,
    required this.isDisabled,
    required super.child,
  });

  final bool isDisabled;

  @override
  bool updateShouldNotify(DisabledWidgetScope oldWidget) {
    return oldWidget.isDisabled != isDisabled;
  }
}

class _DisabledWidgetEffects extends StatelessWidget {
  const _DisabledWidgetEffects({
    required this.child,
    required this.isDisabled,
  });

  final Widget child;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      // opacity: 1.0,
      opacity: isDisabled ? 0.5 : 1.0,
      child: AbsorbPointer(
        // absorbing: false,
        absorbing: isDisabled,
        child: child,
      ),
    );
  }
}
