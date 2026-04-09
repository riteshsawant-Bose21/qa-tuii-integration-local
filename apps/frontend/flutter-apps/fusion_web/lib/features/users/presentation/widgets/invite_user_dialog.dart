import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class InviteUserRow {
  final TextEditingController emailController = TextEditingController();
  String? selectedRole;

  InviteUserRow();

  void dispose() {
    emailController.dispose();
  }
}

class InviteUserDialog extends StatefulWidget {
  final Function(List<Map<String, dynamic>> invites) onInvite;

  const InviteUserDialog({super.key, required this.onInvite});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<InviteUserRow> _inviteRows = [InviteUserRow()];

  final List<String> _availableRoles = ['Designer', 'Admin', 'Technician'];

  @override
  void dispose() {
    for (var row in _inviteRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addAnotherUser() {
    setState(() {
      _inviteRows.add(InviteUserRow());
    });
  }

  void _removeUser(int index) {
    if (_inviteRows.length > 1) {
      setState(() {
        _inviteRows[index].dispose();
        _inviteRows.removeAt(index);
      });
    }
  }

  int _roleToId(String role) {
    const roleMap = {
      'Admin': 1,
      'Designer': 2,
      'Technician': 3,
    };
    return roleMap[role] ?? 3;
  }

  void _handleSendInvites() {
    if (_formKey.currentState!.validate()) {
      List<Map<String, dynamic>> invites = [];

      for (var row in _inviteRows) {
        if (row.emailController.text.isNotEmpty && row.selectedRole != null) {
          invites.add({
            'email': row.emailController.text.trim(),
            'account_type_role_id': _roleToId(row.selectedRole!),
          });
        }
      }

      if (invites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one user to invite'),
          ),
        );
        return;
      }

      widget.onInvite(invites);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colorScheme.elevation3, width: 1.2),
      ),
      backgroundColor: context.colorScheme.elevation1,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invite users to your organization',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add email addresses and assign roles to invite users to your organization.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: context.colorScheme.elevation6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Invite Rows
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ..._inviteRows.asMap().entries.map((entry) {
                        int index = entry.key;
                        InviteUserRow row = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              // Email Field
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: row.emailController,
                                  style: TextStyle(
                                    color: context.colorScheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'name@example.com',
                                    filled: true,
                                    fillColor: context.colorScheme.elevation2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.elevation3,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.elevation3,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Role Dropdown
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: row.selectedRole,
                                  dropdownColor: context.colorScheme.elevation2,
                                  style: TextStyle(
                                    color: context.colorScheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Select role',
                                    filled: true,
                                    fillColor: context.colorScheme.elevation2,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.elevation3,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.elevation3,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: _availableRoles.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: GoogleFonts.inter(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      row.selectedRole = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select a role';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // Remove button (only show if more than 1 row)
                              if (_inviteRows.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => _removeUser(index),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        context.colorScheme.elevation3,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Add Another Button
                      InkWell(
                        onTap: _addAnotherUser,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: context.colorScheme.elevation3,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 20,
                                color: context.colorScheme.elevation6,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add another',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: context.colorScheme.elevation6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.elevation6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSendInvites,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: context.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Send Invites',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
