import 'package:flutter/material.dart';

/// A simple reusable AppBar for the Fusion design system.
///
/// Example:
/// ```dart
/// Scaffold(
///   appBar: FusionAppBar(
///     title: 'Dashboard',
///     themeToggleWidget: IconButton(
///       onPressed: () => toggleTheme(),
///       icon: Icon(Icons.brightness_6),
///     ),
///   ),
///   body: ...
/// )
/// ```
class FusionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;
  final Widget? themeToggleWidget;

  const FusionAppBar({super.key, required this.title, this.actions, this.leading, this.backgroundColor, this.centerTitle = false, this.themeToggleWidget});

  @override
  Widget build(BuildContext context) {
    final List<Widget> appBarActions = <Widget>[];

    // Add custom actions if provided
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    // Add theme toggle widget if provided
    if (themeToggleWidget != null) {
      appBarActions.add(themeToggleWidget!);
    }

    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leading: leading,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
