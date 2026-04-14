import 'package:flutter/material.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/aes67/configation_aes67.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_table.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';

/// Section card: title bar + FusionTable
class StreamSection extends StatelessWidget {
  final String title;
  final String addLabel;
  final List<FusionTableColumn> columns;
  final List<FusionTableRow> rows;
  final void Function(BuildContext context) onAdd;
  final void Function(String rowKey)? onRowTap;
  final String emptyMessage;
  final String semanticId;

  const StreamSection({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.columns,
    required this.rows,
    required this.emptyMessage,
    this.onRowTap,
    required this.semanticId,
  });

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, semanticId),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.elevation2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colorScheme.elevation2),
        ),
        child: Column(
          children: <Widget>[
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_${FusionTestKeys.instance.section_header}'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FusionAppText(
                      semanticId: '${semanticId}_${FusionTestKeys.instance.section_header_text}',
                      text: title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => onAdd(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: SemanticHelper.button(
                          testId: SemanticHelper.createTestId(SemanticTypes.button, '${semanticId}_${FusionTestKeys.instance.section_header_add_button}'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FusionIcon.icon(
                                semanticId: '${semanticId}_${FusionTestKeys.instance.section_header_add_button_icon}',
                                Icons.add,
                                size: 14,
                                color: context.colorScheme.iconWhite,
                              ),
                              const SizedBox(width: 4),
                              FusionAppText(
                                semanticId: '${semanticId}_${FusionTestKeys.instance.section_header_add_button_text}',
                                text: addLabel,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: context.colorScheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Show empty state or table
            if (rows.isEmpty)
              Expanded(
                child: SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_${FusionTestKeys.instance.section_empty_container}'),
                  child: Container(
                    color: context.colorScheme.elevation1,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FusionAppText(
                          semanticId: '${semanticId}_${FusionTestKeys.instance.empty_message}',
                          text: emptyMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SemanticHelper.container(
                          testId: SemanticHelper.createTestId(SemanticTypes.container, '${semanticId}_${FusionTestKeys.instance.empty_add_button}'),
                          child: InkWell(
                            onTap: () => onAdd(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  FusionIcon.icon(
                                    semanticId: '${semanticId}_${FusionTestKeys.instance.empty_add_button_icon}',
                                    Icons.add,
                                    size: 16,
                                    color: context.colorScheme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  FusionAppText(
                                    semanticId: '${semanticId}_${FusionTestKeys.instance.empty_add_button_text}',
                                    text: addLabel,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.colorScheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // FusionTable with calculated height
              Expanded(
                child: Container(
                  color: context.colorScheme.elevation1,
                  child: FusionTable(
                    semanticId: semanticId,
                    columns: columns,
                    rows: rows,
                    onRowTap: onRowTap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
