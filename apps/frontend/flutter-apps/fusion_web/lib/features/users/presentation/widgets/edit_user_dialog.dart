import 'package:flutter/material.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late String? _selectedRole;
  late List<String> _selectedProjects;
  late UserStatus _selectedStatus;

  final List<String> _availableRoles = ['Admin', 'Designer', 'Technician'];

  final List<Map<String, String>> _availableProjects = [
    {'id': 'project-1', 'name': 'Project Alpha'},
    {'id': 'project-2', 'name': 'Project Beta'},
    {'id': 'project-3', 'name': 'Project Gamma'},
    {'id': 'project-4', 'name': 'Project Delta'},
    {'id': 'project-5', 'name': 'Project Epsilon'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedRole = widget.user.roles.isNotEmpty
        ? widget.user.roles.first
        : null;
    _selectedProjects = List.from(widget.user.associatedProjects);
    _selectedStatus = widget.user.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a role')));
        return;
      }

      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        roles: [_selectedRole!],
        status: _selectedStatus,
        associatedProjects: _selectedProjects,
        isActive: _selectedStatus == UserStatus.active,
      );

      widget.onUpdate(updatedUser);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
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
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Update user details and permissions',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          labelStyle: GoogleFonts.montserrat(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address *',
                          labelStyle: GoogleFonts.montserrat(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: GoogleFonts.montserrat(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role and Status Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role *',
                                labelStyle: GoogleFonts.montserrat(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: _availableRoles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(
                                    role,
                                    style: GoogleFonts.montserrat(),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedRole = value;
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<UserStatus>(
                              initialValue: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Status *',
                                labelStyle: GoogleFonts.montserrat(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: UserStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Projects Section
                      Text(
                        'Assigned Projects',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          children: _availableProjects.map((project) {
                            final isSelected = _selectedProjects.contains(
                              project['id'],
                            );
                            return CheckboxListTile(
                              title: Text(
                                project['name']!,
                                style: GoogleFonts.montserrat(),
                              ),
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedProjects.add(project['id']!);
                                  } else {
                                    _selectedProjects.remove(project['id']);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
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
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.montserrat(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Update User',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
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

  // Helper methods for role display
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Designer':
        return Icons.design_services;
      case 'Technician':
        return Icons.engineering;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red[600]!;
      case 'Designer':
        return Colors.purple[600]!;
      case 'Technician':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
