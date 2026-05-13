import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_web/features/users/domain/entities/user_entity.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildRoleChips(List<String> roles, BuildContext context, {bool limit = false}) {
  final displayRoles = limit ? roles.take(2).toList() : roles;

  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [
      ...displayRoles.map((role) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.colorScheme.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colorScheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            role,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.colorScheme.primaryColor,
            ),
          ),
        );
      }),

      if (limit && roles.length > 2)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.colorScheme.elevation3,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+${roles.length - 2}',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: context.colorScheme.elevation6,
            ),
          ),
        ),
    ],
  );
}

Widget buildStatusChip(UserStatus status) {
  Color color = _getStatusColor(status);
  IconData icon = _getStatusIcon(status);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(
        status.displayName,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    ],
  );
}

Color _getStatusColor(UserStatus status) {
  switch (status) {
    case UserStatus.active:
      return Colors.green;
    case UserStatus.invited:
      return Colors.orange;
    case UserStatus.pending:
      return Colors.amber;
    case UserStatus.inactive:
      return Colors.red;
  }
}

IconData _getStatusIcon(UserStatus status) {
  switch (status) {
    case UserStatus.active:
      return Icons.check_circle;
    case UserStatus.invited:
      return Icons.email;
    case UserStatus.pending:
      return Icons.pending;
    case UserStatus.inactive:
      return Icons.block;
  }
}
