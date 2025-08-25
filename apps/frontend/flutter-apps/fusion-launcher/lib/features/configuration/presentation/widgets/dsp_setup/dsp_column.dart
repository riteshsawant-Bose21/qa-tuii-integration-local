import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/constants.dart';
import '../common/vip_configuration.dart';
import '../dro-visualizer/dro_visualizer.dart';
import 'dsp_card.dart';

class DspColumn extends StatefulWidget {
  final List<FusionDevice> fusionDevices;
  final String? vipAddress;
  final String? droAddress;
  final Function() onRequestFusionDeviceList;
  final Function() onSendToDsp;
  final bool isControlMode;

  const DspColumn({
    super.key,
    required this.fusionDevices,
    this.vipAddress,
    required this.onRequestFusionDeviceList,
    this.droAddress,
    required this.onSendToDsp,
    required this.isControlMode,
  });

  @override
  State<DspColumn> createState() => _DspColumnState();
}

class _DspColumnState extends State<DspColumn> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(),
          Divider(
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),

          if (widget.vipAddress != null) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: AppColors.cardSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outline.withAlpha((0.2 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withAlpha((0.8 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.network_check,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Virtual IP Address',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.vipAddress!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      configureVip(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Reconfigure',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _body(),
            ),
          ),
          if (widget.isControlMode) ...<Widget>[
            Divider(
              height: 1,
              color: Colors.grey.shade300,
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: ElevatedButton(
                  onPressed:
                      (widget.vipAddress == null || widget.fusionDevices.isEmpty)
                          ? null
                          : () {
                            widget.onSendToDsp();
                          },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  //add > icon to the button
                  child: const Text(
                    'Push Config',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.memory,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Fusion Devices',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.image_search,
              color: Colors.grey.shade700,
              size: 18,
            ),
            onPressed: () {
              DROVisualizer.openDROVisualizer(context);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: widget.fusionDevices.isNotEmpty ? Colors.grey.shade700 : Colors.transparent,
              size: 18,
            ),
            onPressed:
                widget.fusionDevices.isNotEmpty
                    ? () {
                      widget.onRequestFusionDeviceList();
                    }
                    : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return (widget.droAddress == null || widget.droAddress!.trim().isEmpty)
        ? const Center(
          child: Text(
            'DRO Address is not added yet\n Configure DRO Address to see Fusion Devices',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        )
        : widget.fusionDevices.isEmpty
        ? Center(
          child: FilledButton(
            onPressed: () {
              widget.onRequestFusionDeviceList();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.primary,
            ),
            child: Text(
              'Get Fusion Devices',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.primary),
            ),
          ),
        )
        : ListView.builder(
          itemCount: widget.fusionDevices.length,
          itemBuilder: (BuildContext ctx, int i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DSPDeviceCard(
                device: widget.fusionDevices[i],
                allDevicesInProject: widget.fusionDevices,
                vipAddress: widget.vipAddress,
                isControlMode: widget.isControlMode,
                onConfigureVip: () {
                  configureVip(ctx);
                },
              ),
            );
          },
        );
  }
}
