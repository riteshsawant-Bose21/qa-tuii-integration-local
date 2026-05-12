import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';

class EditUserDialog extends StatefulWidget {
  final UserEntity user;
  final Function(UserEntity updatedUser) onUpdate;

  const EditUserDialog({super.key, required this.user, required this.onUpdate});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedRole;

  final List<String> _availableRoles = ['Admin', 'Designer', 'Technician'];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.roles.isNotEmpty
        ? widget.user.roles.first
        : null;
  }

  void _handleUpdate() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
        return;
      }

      final updatedUser = widget.user.copyWith(
        roles: [_selectedRole!],
      );

      widget.onUpdate(updatedUser);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final displayName = user.name.isEmpty
        ? user.email.split('@').first
        : user.name;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colorScheme.elevation3, width: 1.2),
      ),
      backgroundColor: context.colorScheme.elevation1,
      child: Container(
        width: 520,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit User',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update role for this user',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: context.colorScheme.elevation6,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.colorScheme.elevation6,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Divider(color: context.colorScheme.elevation3),
              const SizedBox(height: 20),

              // Read-only user info block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colorScheme.elevation3),
                ),
                child: Column(
                  children: [
                    _infoRow(context, Icons.person_outline, 'Full Name', displayName),
                    const SizedBox(height: 12),
                    _infoRow(context, Icons.email_outlined, 'Email', user.email),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _infoRow(context, Icons.phone_outlined, 'Phone', user.phone!),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Role Dropdown (only editable field)
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: context.colorScheme.elevation2,
                style: TextStyle(color: context.colorScheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Role *',
                  labelStyle: GoogleFonts.montserrat(
                    color: context.colorScheme.elevation6,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.elevation3),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colorScheme.elevation3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: context.colorScheme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: context.colorScheme.elevation2,
                  prefixIcon: Icon(
                    Icons.shield_outlined,
                    color: context.colorScheme.elevation6,
                  ),
                ),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role, style: GoogleFonts.montserrat()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.montserrat(
                        color: context.colorScheme.elevation6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primaryColor,
                      foregroundColor: context.colorScheme.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
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

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.colorScheme.elevation6),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.elevation6,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
