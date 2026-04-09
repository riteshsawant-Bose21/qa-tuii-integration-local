
import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/features/notification/models/notification_model.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dotted_line.dart';
import 'package:fusion_lib/fusion_lib.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification data;

  const NotificationCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final config = getConfig(data.type,context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: config.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonCircleIcon(
                icon:config.icon,
                iconColor: config.iconColor,
                bgColor: config.iconBg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:context.textTheme.b3Medium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: config.titleColor,
                            ),
                          ),
                        ),
                        Text(
                          data.timeLabel,
                          style:Theme.of(context).textTheme.l2Regular.copyWith(
                            fontWeight: FontWeight.w400,
                            color: context.colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                     Text(
                      data.zone,
                       style:Theme.of(context).textTheme.l1Regular.copyWith(
                         fontWeight: FontWeight.w400,
                         color: context.colorScheme.textSecondary,
                       ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomDottedLine(
            dashLength: 4,
            dashGap: 6,
            thickness: 1,
            color: context.colorScheme.strokeLight,
            cap: StrokeCap.round,
          ),
          const SizedBox(height: 8),
          Row(
            children:  [
              Icon(Icons.storage, color: context.colorScheme.iconDefault, size: 18),
              SizedBox(width: 6),
              Text(
                data.device,
                style:Theme.of(context).textTheme.l1Regular.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textBody,
                ),
              ),
              SizedBox(width: 40),
              Icon(Icons.public, color: context.colorScheme.iconDefault, size: 18),
              SizedBox(width: 6),
              Text(
                data.location,
                style:Theme.of(context).textTheme.l1Regular.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textBody,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
class _NotificationConfig {
  final Color background;
  final Color border;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;
  final IconData icon;

  const _NotificationConfig({
    required this.background,
    required this.border,
    required this.iconBg,
    required this.iconColor,
    required this.titleColor,
    required this.icon,
  });
}

_NotificationConfig getConfig(NotificationType type,BuildContext context) {
  switch (type) {
    case NotificationType.critical:
      return  _NotificationConfig(
        background: Color(0xFF3D0E0D),
        border: Color(0xFF600101),
        iconBg: Color(0xFFE74B49),
        iconColor: context.colorScheme.iconDefault,
        titleColor: Color(0xFFE74B49),
        icon: Icons.shield_outlined,
      );
    case NotificationType.warning:
      return  _NotificationConfig(
        background: Color(0xFF3D210C),
        border: Color(0xFF933E03),
        iconBg: Color(0xFFE78024),
        iconColor: context.colorScheme.iconDefault,
        titleColor: Color(0xFFE78024),
        icon: Icons.warning_amber_rounded,
      );
    case NotificationType.neutral:
      return  _NotificationConfig(
        background: Color(0xFF1A1A18),
        border: Color(0xFF3D3C38),
        iconBg: Theme.of(globalNavigatorKey.currentState!.context).colorScheme.zone1Fill,
        iconColor: context.colorScheme.iconDefault,
        titleColor: context.colorScheme.textSecondary,
        icon: Icons.info_outline,
      );
  }
}
