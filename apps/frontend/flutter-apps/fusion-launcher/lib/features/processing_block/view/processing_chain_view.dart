import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/processing_block/utils/pb_icons.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import 'processing_block_page.dart';
import 'widgets/dotted_line.dart';

class ProcessingChainView extends StatelessWidget {
  const ProcessingChainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
                  _PBIcon(
                    icon: PbIcons.icon1,
                    isActive: true,
                  ),
                  _PBIcon(
                    icon: PbIcons.icon2,
                    isActive: false,
                  ),
                  _PBIcon(
                    icon: PbIcons.icon3,
                    isActive: false,
                  ),
                  _PBIcon(
                    icon: PbIcons.icon4,
                    isActive: false,
                  ),
                  _PBIcon(
                    icon: PbIcons.icon5,
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
        const SizedBox(
          height: 40,
        ),
        Row(
          spacing: 10,
          children: <Widget>[
            const SizedBox(),
            Container(
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                PbIcons.icon1,
                color: Colors.black,
                height: 18,
                width: 18,
              ),
            ),

            const Text(
              "Gate",
            ),
            const Spacer(),
            const Icon(Icons.more_vert),
            const SizedBox(),
          ],
        ),
        const Divider(),
        const Flexible(child: ProcessingBlockPage()),
      ],
    );
  }

  static void showForSource(BuildContext context, Source source) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const Dialog(insetPadding: EdgeInsets.symmetric(horizontal: 200, vertical: 100), child: ProcessingChainView()),
    );
  }
}

class _PBIcon extends StatelessWidget {
  const _PBIcon({required this.icon, required this.isActive});
  final bool isActive;
  final String icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        icon,
        color: Colors.white,
        height: 18,
        width: 18,
      ),
    );
  }
}
