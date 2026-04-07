import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_custom_textfield.dart';

/// Shows the "CREATE SNAPSHOT PAGE" dialog and returns the result.
Future<CreateSnapshotPageResult?> showCreateSnapshotPageDialog({
  required BuildContext context,
  required List<SnapshotsModel> availableSnapshots,
}) {
  return showDialog<CreateSnapshotPageResult>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _CreateSnapshotPageDialog(availableSnapshots: availableSnapshots),
  );
}

/// Result returned by the dialog.
class CreateSnapshotPageResult {
  final String name;
  final List<String> selectedIds;

  const CreateSnapshotPageResult({required this.name, required this.selectedIds});
}

// ─── Dialog widget ─────────────────────────────────────────────────────────────

class _CreateSnapshotPageDialog extends StatefulWidget {
  final List<SnapshotsModel> availableSnapshots;

  const _CreateSnapshotPageDialog({required this.availableSnapshots});

  @override
  State<_CreateSnapshotPageDialog> createState() => _CreateSnapshotPageDialogState();
}

class _CreateSnapshotPageDialogState extends State<_CreateSnapshotPageDialog> {
  late final TextEditingController _nameController;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Untitled_Snapshot');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCreate() {
    Navigator.of(context).pop(
      CreateSnapshotPageResult(
        name: _nameController.text.trim().isEmpty ? 'Untitled_Snapshot' : _nameController.text.trim(),
        selectedIds: _selectedIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: context.colorScheme.elevation1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(context),
              _buildBody(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.strokeLight, width: 1),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: FusionAppText(text: 'CREATE SNAPSHOT PAGE', style: Theme.of(context).textTheme.l1Regular),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: FusionIcon.icon(Icons.close, size: 12, color: context.colorScheme.iconDefault),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Name field ──────────────────────────────────────────────
          FusionCustomTextField(
            label: 'Name',
            borderRadius: 8,
            variant: FusionFieldVariant.neumorphic,
            semanticId: '',
            controller: _nameController,
            height: 24,
          ),

          const SizedBox(height: 12),
          Divider(color: context.colorScheme.strokeLight, thickness: 0.75),
          const SizedBox(height: 7),

          // ── Available snapshots ─────────────────────────────────────
          FusionAppText(
            text: 'Available snapshots',
            style: Theme.of(context).textTheme.l1Regular.copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _SnapshotCheckboxList(
            snapshots: widget.availableSnapshots,
            selectedIds: _selectedIds,
            onToggle: (String id) {
              setState(() {
                _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
              });
            },
          ),
          Divider(color: context.colorScheme.strokeLight, thickness: 0.75),
          const SizedBox(height: 12),

          // ── Create button ───────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: FusionAppButton(
              width: 68,
              height: 32,
              text: 'Create',
              textstyle: context.textTheme.l1Regular,
              semanticId: '',
              borderRadius: 8,
              style: FusionAppButtonStyle.neumorphic,
              onPressed: _onCreate,
            ),
            // child: _CreateButton(onPressed: _onCreate),
          ),
        ],
      ),
    );
  }
}

// ─── Name text field ──────────────────────────────────────────────────────────

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FusionCustomTextField(
      variant: FusionFieldVariant.neumorphic,
      semanticId: '',
      controller: controller,
      height: 30,
    );
  }
}

// ─── Scrollable snapshot checkbox list ───────────────────────────────────────

class _SnapshotCheckboxList extends StatelessWidget {
  final List<SnapshotsModel> snapshots;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;

  const _SnapshotCheckboxList({
    required this.snapshots,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No available snapshots',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colorScheme.textSecondary,
          ),
        ),
      );
    }

    // Show max 5 rows before scrolling (≈ 40px × 5 = 200px)
    final double listHeight = (snapshots.length.clamp(1, 5) * 44).toDouble();

    return SizedBox(
      height: 100,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshots.length,
          itemBuilder: (BuildContext context, int index) {
            final SnapshotsModel snap = snapshots[index];
            final bool isChecked = selectedIds.contains(snap.id);
            return _SnapshotCheckboxItem(
              snapshot: snap,
              isChecked: isChecked,
              onToggle: () => onToggle(snap.id),
            );
          },
        ),
      ),
    );
  }
}

class _SnapshotCheckboxItem extends StatelessWidget {
  final SnapshotsModel snapshot;
  final bool isChecked;
  final VoidCallback onToggle;

  const _SnapshotCheckboxItem({
    required this.snapshot,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: <Widget>[
            FusionCheckbox(
              semanticId: '',
              width: 16,
              height: 16,
              onChanged: onToggle,
              value: isChecked,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                snapshot.name,
                style: Theme.of(context).textTheme.l2Regular.copyWith(
                  color: context.colorScheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Checkbox icon ─────────────────────────────────────────────────────────────

class _CheckboxIcon extends StatelessWidget {
  final bool isChecked;
  const _CheckboxIcon({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isChecked ? context.colorScheme.primaryColor : Colors.transparent,
        border: Border.all(
          color: isChecked ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
          width: 1.5,
        ),
      ),
      child: isChecked ? Icon(Icons.check, size: 12, color: context.colorScheme.primaryWhite) : null,
    );
  }
}

// ─── Create button ─────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation3,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.colorScheme.strokeLight, width: 1),
        ),
        child: Text(
          'Create',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
