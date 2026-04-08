import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../shared/presentation/widgets/common/dropdown_field.dart';
import '../../../shared/presentation/widgets/common/text_field/info_field.dart';
class WifiCredentialsScreen extends StatefulWidget {
  const WifiCredentialsScreen({super.key});

  @override
  State<WifiCredentialsScreen> createState() => _WifiCredentialsScreenState();
}

class _WifiCredentialsScreenState extends State<WifiCredentialsScreen> {
  final TextEditingController ssidController =
  TextEditingController(text: 'Namiths Gym');
  final TextEditingController passwordController =
  TextEditingController(text: '123456789');
  final TextEditingController securityController =
  TextEditingController(text: 'WPA2/WPA3');


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Configure Network'),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Wi-Fi Credentials',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              /// Subtitle
               Text(
                'Enter the credentials of the wifi network you want to connect your devices.',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colorScheme.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              /// SSID
              InfoField(
                label: 'Network name (SSID/Username) *',
                controller: ssidController,
              ),

              const SizedBox(height: 24),


              CommonDropdownField(
                label: 'Security',
                hint: 'Pick Values',
                controller: securityController,
              ),
              const SizedBox(height: 24),
              /// Security
              InfoField(
                label: 'Password',
                obscureText: true,
                controller: passwordController,
              ),

              const Spacer(),

              /// Save button
            ],
          ),
        ),
        bottomNavigationBar: CustomButton(
          enabled: ValueNotifier(true),
          buttonText: 'Save',
          onPressed: () {
            Navigator.pushNamed(context, Routes.configureVIP);
          },
        ),
      ),
    );
  }
}
