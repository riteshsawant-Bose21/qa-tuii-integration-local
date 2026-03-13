import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class WallControllerCardItem extends StatelessWidget {
  final String deviceName;
  final String deviceModel;
  final String location;
  final bool isOnline;
  final VoidCallback? onTap;

  const WallControllerCardItem({
    super.key,
    required this.deviceName,
    required this.deviceModel,
    required this.location,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colorScheme.elevation1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colorScheme.elevation2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Device Image + Status
            Stack(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryWhite,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child:  Icon(Icons.router, color: context.colorScheme.primaryBlack),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: CircleAvatar(
                      radius: 4,
                      backgroundColor: isOnline
                          ? context.colorScheme.volumeGreen
                          : context.colorScheme.textPlaceholder
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            /// Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    deviceName,
                    style: Theme.of(context).textTheme.b3SemiBold!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    deviceModel,
                    style: Theme.of(context).textTheme.l1Regular!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colorScheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.elevation3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      location.toUpperCase(),
                      style: Theme.of(context).textTheme.l2SemiBold!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Arrow Button
            if(isOnline)
            Align(
              alignment: Alignment.topCenter,
              child: FusionContainer(
                  raised:true,
                  borderRadius: 8,
                  child: Container(

                      margin: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right, color: context.colorScheme.iconWhite)
                  )
              ),
            )

          ],
        ),
      ),
    );
  }
}