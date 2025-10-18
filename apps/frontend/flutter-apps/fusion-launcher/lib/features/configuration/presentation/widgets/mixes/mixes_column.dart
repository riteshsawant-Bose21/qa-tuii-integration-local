import 'package:flutter/material.dart';
import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../../core/service_locator.dart';
import '../../viewmodel/project_view_model.dart';
import 'mix_widget.dart';

class MixColumn extends StatefulWidget {
  final List<SourceSet> mixes;
  final List<Source> sources;
  final void Function(SourceSet) onMixUpdated;
  final void Function(SourceSet) onMixDeleted;
  final void Function(SourceSet) onMixAdded;
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
              onMixUpdated: (SourceSet ss) {
                widget.onMixUpdated(ss);
              },
              onSourceRemoved: (String sourceId) {
                serviceLocator<ProjectViewModel>().removeSourceFromSourceSet(sourceId, widget.mixes[i].id);
              },
              onDelete: () {
                widget.onMixDeleted(widget.mixes[i]);
              },
              selectedSources: serviceLocator<ProjectViewModel>().getSourcesInSourceSet(widget.mixes[i].id),
              duplicateMix: () {
                final SourceSet newMix = SourceSet(
                  name: '${widget.mixes[i].name} (Copy)',
                );
                widget.onMixAdded(newMix);
              },
              onSourcesSetUpdated: (String sourceSetId, List<String> newSourceIds) {
                serviceLocator<ProjectViewModel>().updateSourcesInSourceSet(sourceSetId, newSourceIds);
              },
            ),
          ),
    );
  }

  void _addNewMix() {
    final SourceSet newMix = SourceSet(
      name: 'Mix ${widget.mixes.length + 1}',
    );
    widget.onMixAdded(newMix);
  }
}
