import 'package:flutter/material.dart';
import 'package:fusion_app/features/profile/widgets/setting_switch_tile.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dropdown_field.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/phone_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../shared/presentation/widgets/common/text_field/info_field.dart';

class AccountCredentialScreen extends StatefulWidget {
  const AccountCredentialScreen({super.key});

  @override
  State<AccountCredentialScreen> createState() => _AccountCredentialScreenState();
}

class _AccountCredentialScreenState extends State<AccountCredentialScreen> {
  final TextEditingController name =
  TextEditingController(text: 'Steve J');

  final TextEditingController email =
  TextEditingController(text: 'steve.j.smith@email.com');

  final ValueNotifier<bool> emailController = ValueNotifier(true);

  final ValueNotifier<bool> twoFactorController = ValueNotifier(true);

  final ValueNotifier<bool> textNotificationsController = ValueNotifier(false);


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Account Credentials'),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              backGroundColor: context.colorScheme.elevation1,
              enabled: ValueNotifier(true),

              onPressed: (){

              },
              buttonText:'Account Credentials',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              SizedBox(height: 24,),
              InfoField(
                label: 'User Name',
                controller: name,
              ),
              SizedBox(height: 20,),
              InfoField(
                label: 'Email',
                controller: email,
              ),
              SizedBox(height: 20,),
              CommonDivider(paddingValue: 0,),
              SizedBox(height: 20,),
              Text(
                "Settings",
                style: Theme.of(context).textTheme.b2Medium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textDisabled,
                ),
              ),

              const SizedBox(height: 12),

              SettingToggleTile(
                title: "Enable Two-Factor Authentication",
                onChanged: twoFactorController,
              ),
              const SizedBox(height: 16),
              SettingToggleTile(
                title: "Enable Email Notifications & Updates",
                onChanged: emailController,
              ),
              const SizedBox(height: 16),
              SettingToggleTile(
                title: "Enable Text Notifications & Updates",
                onChanged: textNotificationsController,
              ),
            ],
          ),
        )
      ),
    );
  }
}
