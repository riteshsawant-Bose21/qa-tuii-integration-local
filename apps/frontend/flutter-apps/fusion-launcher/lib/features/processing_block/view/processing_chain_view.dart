import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import 'widgets/dotted_line.dart';

class ProcessingChainView extends StatelessWidget {
  const ProcessingChainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// --------------------------------------------------------------------------------
        /// HEADING
        /// --------------------------------------------------------------------------------
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  "SOURCE PROCESSING_WIRELESS MIC 1",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 10,
        ),

        /// --------------------------------------------------------------------------------
        /// HEADING
        /// --------------------------------------------------------------------------------
        SizedBox(
          width: 600,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              const DottedLine(
                dotSize: 5,
                spacing: 4,
                color: Colors.grey,
              ),
              Row(
                spacing: 10,
                children: <Widget>[
                  const SizedBox(
                    width: 30,
                  ),
                  const _PBIcon(
                    icon: Icons.gas_meter,
                    isActive: true,
                  ),
                  const _PBIcon(
                    icon: Icons.graphic_eq,
                    isActive: false,
                  ),
                  const _PBIcon(
                    icon: Icons.grain_sharp,
                    isActive: false,
                  ),
                  const _PBIcon(
                    icon: Icons.account_tree_outlined,
                    isActive: false,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(5)),
                    padding: const EdgeInsets.all(5),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void showForSource(BuildContext context, Source source) {
    showDialog(context: context, builder: (BuildContext context) => const Dialog(child: ProcessingChainView()));
  }
}

class _PBIcon extends StatelessWidget {
  const _PBIcon({required this.icon, required this.isActive, this.isDense = false});
  final bool isActive;
  final IconData icon;
  final bool isDense;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey.shade400, borderRadius: BorderRadius.circular(isDense ? 5 : 10)),
      padding: EdgeInsets.all(isDense ? 5 : 10),
      child: Icon(
        icon,
        color: Colors.white,
        size: isDense ? 14 : 18,
      ),
    );
  }
}
