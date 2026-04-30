import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:intl/intl.dart';

class UserProfileDialog extends StatelessWidget {
  final UserEntity user;
  final VoidCallback? onEdit;
  final VoidCallback? onActivate;
  final VoidCallback? onDeactivate;
  final VoidCallback? onResendInvite;

  const UserProfileDialog({
    super.key,
    required this.user,
    this.onEdit,
    this.onActivate,
    this.onDeactivate,
    this.onResendInvite,
  });

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return const Color(0xFF3E996E);
      case UserStatus.invited:
        return Colors.orange;
      case UserStatus.pending:
        return Colors.amber;
      case UserStatus.inactive:
        return const Color(0xFFE57373);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colorScheme.elevation3, width: 1.2),
      ),
      backgroundColor: context.colorScheme.elevation1,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Profile Picture
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: context.colorScheme.elevation3,
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: user.avatar == null
                        ? Text(
                            user.name.isNotEmpty
                                ? user.name.substring(0, 1).toUpperCase()
                                : user.email.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.textPrimary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 24),

                  // User Basic Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: context.colorScheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  user.status,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.status.displayName,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(user.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: context.colorScheme.elevation6,
                          ),
                        ),
                        if (user.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phone!,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: context.colorScheme.elevation6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Close Button
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.colorScheme.elevation6,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Type & Roles Section
                    _buildSection(
                      'User Type & Roles',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('User Type', user.userType.displayName),
                          const SizedBox(height: 8),
                          Text(
                            'Roles:',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.elevation6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.roles.map((role) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.elevation3,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  role,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: context.colorScheme.textPrimary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Permissions Section
                    _buildSection(
                      'Permissions',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.permissions.map((permission) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primaryColor
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.colorScheme.primaryColor
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              permission,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: context.colorScheme.primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Projects Section
                    _buildSection(
                      'Assigned Projects',
                      user.associatedProjects.isEmpty
                          ? Text(
                              'No projects assigned',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: context.colorScheme.elevation6,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: user.associatedProjects.map((
                                projectId,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.folder_outlined,
                                        size: 16,
                                        color: context.colorScheme.elevation6,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        projectId,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color:
                                              context.colorScheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Activity & History Section
                    _buildSection(
                      'Activity & History',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Joined',
                            dateFormat.format(user.createdAt),
                          ),
                          if (user.inviteDate != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Invited',
                              dateFormat.format(user.inviteDate!),
                            ),
                          ],
                          if (user.lastLoginAt != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Last Login',
                              dateFormat.format(user.lastLoginAt!),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Last Login', 'Never'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.colorScheme.elevation3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Resend Invite Button
                  if (user.status == UserStatus.invited ||
                      user.status == UserStatus.pending)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onResendInvite?.call();
                      },
                      icon: Icon(
                        Icons.email,
                        color: context.colorScheme.elevation6,
                      ),
                      label: Text(
                        'Resend Invite',
                        style: GoogleFonts.montserrat(
                          color: context.colorScheme.elevation6,
                        ),
                      ),
                    ),

                  const SizedBox(width: 16),

                  // Activate/Deactivate Button
                  if (user.isActive)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDeactivate?.call();
                      },
                      icon: const Icon(Icons.block),
                      label: Text(
                        'Deactivate',
                        style: GoogleFonts.montserrat(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE57373),
                        side: const BorderSide(color: Color(0xFFE57373)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onActivate?.call();
                      },
                      icon: const Icon(Icons.check_circle),
                      label: Text('Activate', style: GoogleFonts.montserrat()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3E996E),
                        side: const BorderSide(color: Color(0xFF3E996E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  const SizedBox(width: 16),

                  // Edit Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit?.call();
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(
                      'Edit User',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorScheme.primaryColor,
                      foregroundColor: context.colorScheme.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.elevation6,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: context.colorScheme.textPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
