import 'package:flutter/material.dart';

class ExpandableGroup extends StatefulWidget {
  final String title;
  final bool expanded;
  final VoidCallback? onToggle;
  final List<Widget> children;

  const ExpandableGroup({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  State<ExpandableGroup> createState() => _ExpandableGroupState();
}

class _ExpandableGroupState extends State<ExpandableGroup> {
  bool expanded=false;

  @override
  void initState() {
    expanded = widget.expanded;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PanelHeader(
          title: widget.title,
          expanded: expanded,
          onTap: (){
            expanded=!expanded;
            setState(() {
            });
          },
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(children: widget.children)
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
class _PanelHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  const _PanelHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // 🔹 Chevron (LEFT)
            AnimatedRotation(
              turns: expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_up,
                size: 20,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 8),

            // 🔹 Title
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFB4AFA6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.03,
                ),
              ),
            ),

            // 🔹 Action Icons (RIGHT)
            const _PanelIcon(Icons.link),
            const SizedBox(width: 20),
            const _PanelIcon(Icons.tune),
            const SizedBox(width: 20),
            const _PanelIcon(Icons.settings_input_component),
          ],
        ),
      ),
    );
  }
}

class _PanelIcon extends StatelessWidget {
  final IconData icon;

  const _PanelIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Icon(
        icon,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}
