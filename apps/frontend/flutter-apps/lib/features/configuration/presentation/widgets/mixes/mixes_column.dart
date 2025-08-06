import 'package:flutter/material.dart';

import '../../../../../core/models/mix_entity.dart';
import '../../../../../core/models/source_entity.dart';
import 'mix_widget.dart';

class MixColumn extends StatefulWidget {
  final List<Mix> mixes;
  final List<Source> sources;
  final void Function(Mix) onMixUpdated;
  final void Function(Mix) onMixDeleted;
  final void Function(Mix) onMixAdded;
  final bool isControlMode;

  const MixColumn({
    super.key,
    required this.mixes,
    required this.sources,
    required this.onMixUpdated,
    required this.onMixDeleted,
    required this.onMixAdded,
    required this.isControlMode,
  });

  @override
  State<MixColumn> createState() => _MixColumnState();
}

class _MixColumnState extends State<MixColumn> {
  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _body(),
            ),
          ),
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
            Icons.equalizer,
            size: 18,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Source Functions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          if (!widget.isControlMode)
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Colors.grey.shade700,
                size: 18,
              ),
              onPressed: _addNewMix,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (widget.mixes.isEmpty) {
      return const Center(
        child: Text(
          'No mixes created\nClick + to add',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      itemCount: widget.mixes.length,
      itemBuilder:
          (BuildContext ctx, int i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MixWidget(
              mix: widget.mixes[i],
              availableSources: widget.sources,
              isControlMode: widget.isControlMode,
              onMixUpdated: (Mix ss) {
                widget.onMixUpdated(ss);
              },
              onDelete: () {
                widget.onMixDeleted(widget.mixes[i]);
              },
              duplicateMix: () {
                final Mix newMix = Mix(
                  name: '${widget.mixes[i].name} (Copy)',
                  sourceIds: List<String>.from(widget.mixes[i].sourceIds),
                  processingBlocks: widget.mixes[i].processingBlocks,
                );
                widget.onMixAdded(newMix);
              },
            ),
          ),
    );
  }

  void _addNewMix() {
    final Mix newMix = Mix(
      name: 'Mix ${widget.mixes.length + 1}',
    );
    widget.onMixAdded(newMix);
  }
}
