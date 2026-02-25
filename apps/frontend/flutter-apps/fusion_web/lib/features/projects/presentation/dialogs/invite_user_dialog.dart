import 'package:flutter/material.dart';
import 'package:fusion_web/features/projects/data/models/project_model.dart';

class InviteUserDialog extends StatefulWidget {
  final ProjectModel project;

  const InviteUserDialog({
    super.key,
    required this.project,
  });

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final List<_InviteRow> _rows = [_InviteRow()];

  bool _isSubmitting = false;

  void _addRow() {
    setState(() {
      _rows.add(_InviteRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length == 1) return;
    setState(() {
      _rows.removeAt(index);
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.emailController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),

      /// TITLE WITH CLOSE
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Invite Users',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Subtitle
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Invite one or more users to this project by entering their email and selecting a role.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),

              /// Dynamic rows
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      /// Email
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: row.emailController,
                          decoration: const InputDecoration(
                            hintText: 'user@example.com',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email required';
                            }
                            if (!value.contains('@')) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      /// Role
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: row.role,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Viewer', child: Text('Viewer')),
                            DropdownMenuItem(
                                value: 'Editor', child: Text('Editor')),
                            DropdownMenuItem(
                                value: 'Admin', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              row.role = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// Remove button
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeRow(index),
                      ),
                    ],
                  ),
                );
              }),

              /// Add another button
              OutlinedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text('Add Another User'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ],
          ),
        ),
      ),

      /// ACTIONS
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invites'),
        ),
      ],
    );
  }
}

/// Helper model
class _InviteRow {
  final TextEditingController emailController = TextEditingController();
  String role = 'Viewer';
}
