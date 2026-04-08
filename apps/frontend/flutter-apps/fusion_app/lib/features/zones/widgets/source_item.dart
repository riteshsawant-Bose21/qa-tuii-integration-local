import 'package:flutter/material.dart';
import 'package:fusion_app/core/models/scheme_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/checkbox_field.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_lib/fusion_lib.dart' hide Source;
class SourceCard extends StatelessWidget {
  final Source source;
  final bool showCheckbox;
  final bool selected;
  const SourceCard({super.key,required this.source,this.showCheckbox = false,this.selected=false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  selected ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation2,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.colorScheme.elevation2),
            ),
            child: Icon(Icons.multitrack_audio,
                color: context.colorScheme.iconDefault),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              source!.sourceName!,
              style: Theme.of(context)
                  .textTheme
                  .l1Bold
                  .copyWith(color: context.colorScheme.textPrimary),
            ),
          ),
          if(showCheckbox)
          CommonCheckBox(
              isSelected: selected
          )
            else
          Icon(Icons.keyboard_arrow_down,
              color: context.colorScheme.iconWhite)
        ],
      ),
    );
  }
}
