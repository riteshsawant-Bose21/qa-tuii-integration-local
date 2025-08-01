import 'package:flutter/material.dart';

class CollapsibleSidePanel extends StatefulWidget {
  final Widget child;
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final double expandedWidth;
  final double collapsedWidth;
  final bool disableCollapsing;

  const CollapsibleSidePanel({
    super.key,
    required this.child,
    this.title = 'Properties',
    this.icon = Icons.tune,
    this.initiallyExpanded = true,
    this.expandedWidth = 280.0,
    this.collapsedWidth = 40.0,
    this.disableCollapsing = false,
  });

  @override
  State<CollapsibleSidePanel> createState() => _CollapsibleSidePanelState();
}

class _CollapsibleSidePanelState extends State<CollapsibleSidePanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? widget.expandedWidth : widget.collapsedWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            !_isExpanded
                ? Border(
                  left: BorderSide(color: Colors.grey.shade200, width: 1),
                )
                : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // only show header extras once we're past the collapsed width + some padding
          final bool showHeaderExtras = constraints.maxWidth > widget.collapsedWidth + 50;
          // only show the content body once we're a bit past the collapsed width
          final bool showBody = constraints.maxWidth > widget.collapsedWidth + 16;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration:
                    _isExpanded
                        ? BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                        )
                        : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // toggle button
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onPressed: widget.disableCollapsing ? null : _toggle,
                        padding: EdgeInsets.zero,
                        tooltip: _isExpanded ? 'Collapse Panel' : 'Expand Panel',
                      ),
                    ),

                    // title + icon only once we have room
                    if (_isExpanded && showHeaderExtras) ...<Widget>[
                      const SizedBox(width: 8),
                      Icon(widget.icon, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isExpanded ? 1.0 : 0.0,
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Body
              if (_isExpanded && showBody)
                Expanded(
                  child: widget.child,
                ),
            ],
          );
        },
      ),
    );
  }
}
