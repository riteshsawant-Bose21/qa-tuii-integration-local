import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/constants.dart';

class ProcessingChainWidget extends StatefulWidget {
  final List<ProcessingBlockModel> processingBlocks;
  final void Function(List<ProcessingBlockModel>) onProcessingChainChanged;

  const ProcessingChainWidget({
    super.key,
    required this.processingBlocks,
    required this.onProcessingChainChanged,
  });

  @override
  State<ProcessingChainWidget> createState() => _ProcessingChainWidgetState();
}

class _ProcessingChainWidgetState extends State<ProcessingChainWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addBlock() {
    final int ts = DateTime.now().millisecondsSinceEpoch;
    final ProcessingBlockModel newBlock = ProcessingBlockModel(
      id: 'block_$ts',
      name: 'Block ${widget.processingBlocks.length + 1}',
      properties: <PropertySetting>[],
      algorithmId: '',
    );

    widget.onProcessingChainChanged(<ProcessingBlockModel>[...widget.processingBlocks, newBlock]);

    // scroll to end after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              "Processing",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                for (int i = 0; i < widget.processingBlocks.length; i++) ...<Widget>[
                  ProcessingBlockWidget(
                    block: widget.processingBlocks[i],
                    onBlockChanged: (ProcessingBlockModel updated) {
                      final List<ProcessingBlockModel> blocks = <ProcessingBlockModel>[...widget.processingBlocks];
                      blocks[i] = updated;
                      widget.onProcessingChainChanged(blocks);
                    },
                    onDelete: () {
                      final List<ProcessingBlockModel> blocks = <ProcessingBlockModel>[...widget.processingBlocks]..removeAt(i);
                      widget.onProcessingChainChanged(blocks);
                    },
                  ),
                  if (i < widget.processingBlocks.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    onPressed: _addBlock,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessingBlockWidget extends StatelessWidget {
  final ProcessingBlockModel block;
  final void Function(ProcessingBlockModel) onBlockChanged;
  final VoidCallback onDelete;

  const ProcessingBlockWidget({
    super.key,
    required this.block,
    required this.onBlockChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 4.0,
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Text(
                //   block.type,
                //   style: const TextStyle(
                //     fontSize: 8,
                //     color: Colors.grey,
                //   ),
                // ),
              ],
            ),
            const SizedBox(
              width: 4.0,
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 12,
                color: Colors.red,
              ),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            ),
          ],
        ),
      ),
    );
  }
}
