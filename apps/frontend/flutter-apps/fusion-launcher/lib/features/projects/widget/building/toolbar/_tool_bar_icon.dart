part of 'canvas_toolbar.dart';

class _ToolBarIcon extends StatelessWidget {
  const _ToolBarIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: FusionFlatContainer(
        toolTip: label,
        semanticsId: "canvas_tool_${label.toLowerCase()}",
        color: isSelected ? context.colorScheme.elevation3 : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        borderColor: Colors.transparent,
        child: FusionImage.asset(
          "assets/icons/building_page/$icon",
          width: 24,
          assetColor: context.colorScheme.primaryWhite,
        ),
      ),
    );
  }
}
