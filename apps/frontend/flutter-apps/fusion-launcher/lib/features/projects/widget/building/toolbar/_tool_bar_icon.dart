part of 'canvas_toolbar.dart';

class _ToolBarIcon extends StatelessWidget {
  const _ToolBarIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isEnabled;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: FusionFlatContainer(
        toolTip: label,
        semanticsId: "canvas_tool_${label.toLowerCase()}",
        color: isSelected ? context.colorScheme.elevation3 : Colors.transparent,
        isSelected: isSelected,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        borderColor: Colors.transparent,
        child: FusionImageAuto(
          path: "assets/icons/building_page/$icon",
          width: 24,
          color: isEnabled ? context.colorScheme.primaryWhite : context.colorScheme.iconDisabled,
        ),
      ),
    );
  }
}
