import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_launcher/features/wiring_design/controller/component_db.dart';
import 'package:fusion_launcher/features/wiring_design/controller/helpers/connection_methods_extension.dart';
import 'package:fusion_launcher/features/wiring_design/model/model.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

import '../../controller/circuit_controller.dart';
import '../widgets/port_widget.dart';

class PortConnectionOverlay extends StatefulWidget {
  const PortConnectionOverlay({
    super.key,
    required this.port,
    required this.componentDB,
    required this.controller,
  });
  final CircuitPort port;
  final ComponentDb componentDB;
  final CircuitController controller;
  @override
  State<PortConnectionOverlay> createState() => _PortConnectionOverlayState();
}

class _PortConnectionOverlayState extends State<PortConnectionOverlay> {
  final Map<CircuitComponent, List<CircuitPort>> possibleConnections = <CircuitComponent, List<CircuitPort>>{};
  @override
  void initState() {
    super.initState();
    _initializePossibleConnections();
  }

  @override
  void didUpdateWidget(covariant PortConnectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initializePossibleConnections();
  }

  void _initializePossibleConnections() {
    possibleConnections.clear();
    final List<CircuitComponent> allComponents = widget.controller.state.components;
    for (final CircuitComponent component in allComponents) {
      if (component.id == widget.port.parent.id) {
        continue;
      }
      final List<CircuitPort> compatiblePorts = <CircuitPort>[];
      for (final CircuitPort port in component.ports) {
        if (widget.port.canConnect(port) && !widget.controller.hasConnection(port)) {
          compatiblePorts.add(port);
        }
      }
      if (compatiblePorts.isNotEmpty) {
        possibleConnections[component] = compatiblePorts;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.elevation2,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedDefaultTextStyle(
              style:
                  context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.portOverlayTitle,
                  ) ??
                  const TextStyle(),
              duration: const Duration(milliseconds: 100),
              child: Row(
                children: <Widget>[
                  const Text("Connect port "),
                  PortWidget(
                    port: widget.port,
                  ),
                  const Text(" to"),
                ],
              ),
            ),

            //  Text.rich(
            //   TextSpan(
            //     text:,
            //     children: <InlineSpan>[
            //       WidgetSpan(
            //         child: PortWidget(
            //           port: widget.port,
            //         ),
            //       ),
            //       const TextSpan(text: " to"),
            //     ],
            //   ),
            // style: context.textTheme.labelLarge?.copyWith(
            //   color: context.colorScheme.portOverlayTitle,
            // ),
            // ),
          ),
        ),

        const SizedBox(
          height: 10,
        ),
        for (final CircuitComponent component in possibleConnections.keys) ...<Widget>[
          FusionExpansionPanel(
            titleBuilder:
                (BuildContext context, bool isExpanded) => Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 10,
                    ),
                    Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildName(component),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
            content: Column(
              spacing: 2,
              children: <Widget>[
                for (final CircuitPort port in possibleConnections[component]!) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    child: InkWell(
                      onTap: () {
                        widget.controller.addWire(
                          widget.port,
                          port,
                        );
                      },
                      child: Row(
                        spacing: 5,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(
                            width: 8,
                          ),
                          PortWidget(
                            port: port,
                          ),

                          // Container(
                          //   decoration: BoxDecoration(
                          //     border: Border.all(
                          //       color: context.colorScheme.inactivePortBG,
                          //       width: 2,
                          //     ),
                          //     shape: BoxShape.circle,
                          //   ),
                          //   padding: const EdgeInsets.all(6),
                          //   child: Text(
                          //     "${port.data.label}",
                          //     style: context.textTheme.bodySmall?.copyWith(
                          //       fontSize: 8,
                          //     ),
                          //   ),
                          // ),
                          Text(
                            port.data.description ?? port.data.type.description,
                            style: context.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  String _buildName(CircuitComponent component) {
    final String label2 = component.data.label;
    final String parentName = component.parent == null ? "" : "${_buildName(component.parent!)} > ";
    return parentName + label2;
  }
}

class FusionExpansionPanel extends StatefulWidget {
  const FusionExpansionPanel({
    super.key,
    required this.content,
    required this.titleBuilder,
    this.initiallyExpanded = true,
  });
  final Widget Function(BuildContext context, bool isExpanded) titleBuilder;
  final Widget content;
  final bool initiallyExpanded;
  @override
  State<FusionExpansionPanel> createState() => _FusionExpansionPanelState();
}

class _FusionExpansionPanelState extends State<FusionExpansionPanel> {
  bool isExpanded = false;
  void toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        children: <Widget>[
          InkWell(
            onTap: toggleExpanded,
            child: widget.titleBuilder(context, isExpanded),
          ),
          if (isExpanded) widget.content,
        ],
      ),
    );
  }
}
