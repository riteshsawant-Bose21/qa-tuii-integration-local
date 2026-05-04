import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

import '../../../view_model/add_source_viewmodel.dart';

class SourceNameTextfield extends StatefulWidget {
  const SourceNameTextfield({super.key, required this.addSourceViewModel});
  final AddSourceViewModel addSourceViewModel;

  @override
  State<SourceNameTextfield> createState() => _SourceNameTextfieldState();
}

class _SourceNameTextfieldState extends State<SourceNameTextfield> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isHoveringField = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          semanticId: 'scheduler_form_name_field_section_label',
          text: "Source Name",
          style: Theme.of(context).textTheme.l1Medium.withColor(context.colorScheme.textPrimary),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringField = true),
          onExit: (_) => setState(() => _isHoveringField = false),
          child: FusionTextField(
            focusNode: _focusNode,
            maxLength: 30,
            semanticFieldId: 'scheduler_form_name_field',
            hintText: "Enter schedule name",
            decoration: InputDecoration(
              hintText: "Enter schedule name",
              hintStyle: context.textTheme.b3Regular.withColor(context.colorScheme.textPlaceholder),
              counterText: '',
              fillColor: _isFocused ? context.colorScheme.elevation2 : Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colorScheme.strokeLight, width: 1),
              ),
              hoverColor: context.colorScheme.elevation2,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colorScheme.strokeLight, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (String value) {
              widget.addSourceViewModel.setSelectedSourceName(value);
            },
          ),
        ),
      ],
    );
  }
}
