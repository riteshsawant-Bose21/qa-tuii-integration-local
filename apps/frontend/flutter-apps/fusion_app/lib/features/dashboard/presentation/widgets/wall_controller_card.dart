import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/circle_icon.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dotted_line.dart';
import 'package:fusion_lib/fusion_lib.dart';

class HomeWallControllerCard extends StatelessWidget {

  final String title;
  final String subtitle;

  const HomeWallControllerCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.pushNamed(context, Routes.wallControllerPage);

      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A18),
          borderRadius: BorderRadius.circular(20),
          boxShadow:  [
            BoxShadow(
              color: Color(0xFFFFFFFF).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CommonCircleIcon(
              icon: Icons.calendar_today_outlined,
              iconColor: context.colorScheme.iconWhite,
              bgColor:  context.colorScheme.zone9Fill,
            ),

            const SizedBox(width: 16),

            /// Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.b3Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color:context.colorScheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.textTheme.l1Regular.copyWith(
                      fontWeight: FontWeight.w400,
                      color:context.colorScheme.textBody,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: context.colorScheme.iconWhite, size: 24)
          ],
        )
      ),
    );
  }
}
