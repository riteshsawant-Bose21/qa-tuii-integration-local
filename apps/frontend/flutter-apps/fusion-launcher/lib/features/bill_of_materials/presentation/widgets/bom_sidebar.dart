part of '../bill_of_materials_page.dart';

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _BomSidebarItem {
  final IconData icon;
  final String label;
  final BomCategory category;
  const _BomSidebarItem({required this.icon, required this.label, required this.category});
}

class _BomSidebar extends StatelessWidget {
  const _BomSidebar({required this.selected, required this.onSelected});
  final BomCategory selected;
  final ValueChanged<BomCategory> onSelected;

  static const List<_BomSidebarItem> _items = <_BomSidebarItem>[
    _BomSidebarItem(icon: Icons.list_alt_outlined, label: 'All', category: BomCategory.all),
    _BomSidebarItem(icon: Icons.volume_up_outlined, label: 'Loudspeakers', category: BomCategory.loudSpeakers),
    _BomSidebarItem(icon: Icons.settings_remote_outlined, label: 'Controllers', category: BomCategory.controllers),
    _BomSidebarItem(icon: Icons.amp_stories_outlined, label: 'Amplifiers', category: BomCategory.amplifiers),
    _BomSidebarItem(icon: Icons.memory_outlined, label: 'Processors', category: BomCategory.processors),
    _BomSidebarItem(icon: Icons.device_hub_outlined, label: 'Endpoints', category: BomCategory.endpoints),
    _BomSidebarItem(icon: Icons.hardware_outlined, label: 'Hardware Requirements', category: BomCategory.hardwareRequirements),
  ];

  @override
  Widget build(BuildContext context) {
    return FusionFlatContainer(
      width: 237,
      semanticsId: 'building_left_side_panel',
      // padding: const EdgeInsets.all(0),
      margin: const EdgeInsets.only(top: 2, left: 2),
      padding: const EdgeInsets.all(16),
      // decoration: BoxDecoration(
      //   color: context.colorScheme.elevation1,
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(color: context.colorScheme.strokeLight),
      // ),
      child: Column(
        children: <Widget>[
          ..._items.map(
            (_BomSidebarItem item) => _SidebarTile(
              icon: item.icon,
              label: item.label,
              selected: selected == item.category,
              onTap: () => onSelected(item.category),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.selected || _isHovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  widget.selected
                      ? context.colorScheme.elevation3
                      : _isHovered
                      ? context.colorScheme.elevation2
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: highlighted ? context.colorScheme.textPrimary : context.colorScheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FusionAppText(
                    semanticId: 'bom_sidebar_${widget.label}',
                    text: widget.label,
                    maxLine: 1,
                    style: context.textTheme.l1Regular.withColor(highlighted ? context.colorScheme.textPrimary : context.colorScheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
