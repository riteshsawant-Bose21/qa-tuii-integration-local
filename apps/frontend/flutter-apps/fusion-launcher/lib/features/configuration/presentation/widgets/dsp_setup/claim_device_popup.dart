import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_lib/fusion_utils/app_settings.dart';
import 'package:fusion_lib/fusion_utils/shared_preference_handler.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../../core/utils/broadcast_controllers.dart';

class QRClaimPopup extends StatefulWidget {
  final String deviceIdToClaim;
  final String? deviceName;

  const QRClaimPopup({
    super.key,
    required this.deviceIdToClaim,
    this.deviceName,
  });

  static Future<void> show({
    required BuildContext context,
    required String deviceIdToClaim,
    String? deviceName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return QRClaimPopup(
          deviceIdToClaim: deviceIdToClaim,
          deviceName: deviceName,
        );
      },
    );
  }

  @override
  State<QRClaimPopup> createState() => _QRClaimPopupState();
}

class _QRClaimPopupState extends State<QRClaimPopup> {
  late final String claimUrl;

  @override
  void initState() {
    claimUrl =
        "http://${serviceLocator<FusionPreferences>().cloudWebUrl}/claim/${widget.deviceIdToClaim}?token=${serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.accessToken)}";
    super.initState();
  }

  Future<void> _launchUrl(BuildContext context) async {
    cloudRedirectUrl = "claim/${widget.deviceIdToClaim}?token=${serviceLocator<SharedPreferencesHandler>().getString(SharedPreferenceKeys.accessToken)}";
    debugPrint("Claim URL: $claimUrl");
    Navigator.pop(context);
    projectTabBroadcastController.add(cloudTableIndex);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Title
            Text(
              'Claim Device',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),

            if (widget.deviceName != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                widget.deviceName!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: PrettyQrView.data(
                data: claimUrl,
                decoration: const PrettyQrDecoration(
                  // image: PrettyQrDecorationImage(
                  //   image: AssetImage('assets/images/bose_pro_logo_b.png'),
                  // ),
                  quietZone: PrettyQrQuietZone.zero,
                ),
              ),
            ),

            const SizedBox(height: 5),

            //Scan QR Code Text
            Text(
              'Scan QR code to claim ',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            Text(
              'OR ',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // Claim Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _launchUrl(context),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Click here to claim'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Close Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
