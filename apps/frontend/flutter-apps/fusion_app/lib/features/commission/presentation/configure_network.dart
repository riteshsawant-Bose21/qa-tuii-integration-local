import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ConfigureNetworkScreen extends StatelessWidget {
  const ConfigureNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Configure Network'),
        body:_Content(),
        bottomNavigationBar: CustomButton(
          onPressed: () {
            // TODO: Configure network action
            Navigator.pushNamed(
                context,
                Routes.configureNetworkSearch
            );
          },
          enabled: ValueNotifier(true),
          buttonText: 'Configure network',
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Illustration
            SizedBox(
              height: 180,
              child: Image.asset(
                'assets/img.png',
                fit: BoxFit.contain,
                color:  context.colorScheme.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // 🔹 Title
             Text(
              'Configure your devices to\nconnect to the network',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.h6BoldMobile.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Description
             Text(
              'Allow your project to sync with actual\nhardware installations to monitor and control\nthe complete audio system',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.b3Regular.copyWith(
                fontWeight: FontWeight.w400,
                color: context.colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
