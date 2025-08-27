import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

class ExpandableTileWidget extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const ExpandableTileWidget({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableTileWidget> createState() => _ExpandableTileWidgetState();
}

class _ExpandableTileWidgetState extends State<ExpandableTileWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.initiallyExpanded ? 1.0 : 0.0,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleExpansionChanged(bool expanded) {
    if (expanded) {
      _rotationController.forward();
    } else {
      _rotationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.white,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: ExpansionTile(
          minTileHeight: 24,
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          trailing: _RotatingIcon(
            animation: _rotationAnimation,
            color: theme.colorScheme.fusionTextViewColor,
          ),
          onExpansionChanged: _handleExpansionChanged,
          iconColor: theme.colorScheme.fusionTextViewColor,
          collapsedIconColor: theme.colorScheme.fusionTextViewColor,
          title: _SectionTitle(title: widget.title),
          initiallyExpanded: widget.initiallyExpanded,
          children: <Widget>[widget.child],
        ),
      ),
    );
  }
}

class _RotatingIcon extends StatelessWidget {
  const _RotatingIcon({
    required this.animation,
    required this.color,
  });

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder:
          (BuildContext context, Widget? child) => RotationTransition(
            turns: animation,
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: color,
            ),
          ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 9,
      ),
    );
  }
}
