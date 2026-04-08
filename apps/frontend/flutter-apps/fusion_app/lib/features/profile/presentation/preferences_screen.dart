import 'package:flutter/material.dart';
import 'package:fusion_app/features/profile/widgets/setting_switch_tile.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dropdown_field.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/phone_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../shared/presentation/widgets/common/text_field/info_field.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final TextEditingController measurements =
  TextEditingController();

  final TextEditingController currency =
  TextEditingController();



  final TextEditingController language = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController discount = TextEditingController();

  final ValueNotifier<bool> productController = ValueNotifier(true);

  final ValueNotifier<bool> projectController = ValueNotifier(true);

  final ValueNotifier<bool> trainingController = ValueNotifier(false);


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Preferences'),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              backGroundColor: context.colorScheme.elevation1,
              enabled: ValueNotifier(true),
              onPressed: (){

              },
              buttonText:'Account Preferences',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              SizedBox(height: 24,),
              CommonDropdownField(
                label: 'Measurement Units',
                hint: 'Select',
                controller: measurements,
              ),
              SizedBox(height: 20,),
              CommonDropdownField(
                label: 'Currency',
                hint: 'Select',
                controller: currency,
              ),
              SizedBox(height: 20,),
              CommonDropdownField(
                label: 'Language',
                hint: 'Select',
                controller: language,
              ),
              SizedBox(height: 20,),
              CommonDropdownField(
                label: 'Location',
                hint: 'Select',
                controller: location,
              ),
              SizedBox(height: 20,),
              InfoField(
                label: 'Discount',
                controller: discount,
                hint: '0.0',
              ),
              const SizedBox(height: 20),
              CommonDivider(paddingValue: 0,),
              SizedBox(height: 20,),
              Text(
                "Notifications",
                style: Theme.of(context).textTheme.b2Medium!.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.textDisabled,
                ),
              ),

              const SizedBox(height: 20),

              SettingToggleTile(
                title: "Product Updates",
                onChanged: productController,
              ),
              const SizedBox(height: 16),
              SettingToggleTile(
                title: "Project Activity",
                onChanged: projectController,
              ),
              const SizedBox(height: 16),
              SettingToggleTile(
                title: "Training & Resources",
                onChanged: trainingController,
              ),
              const SizedBox(height: 16),
            ],
          ),
        )
      ),
    );
  }
}