import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dropdown_field.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/phone_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../shared/presentation/widgets/common/text_field/info_field.dart';

class PersonalInformationScreen extends StatelessWidget {
   PersonalInformationScreen({super.key});

  final TextEditingController name =
  TextEditingController(text: 'Steve J');
  final TextEditingController org =
  TextEditingController(text: 'Bose Professional');

  final TextEditingController jobRole =
  TextEditingController(text: 'Director');
  final TextEditingController email =
  TextEditingController(text: 'steve.j.smith@email.com');
   final TextEditingController zipCode =
   TextEditingController(text: '575009');
   final TextEditingController address =
   TextEditingController(text: '');

   final TextEditingController country =
   TextEditingController(text: '');
   final TextEditingController city =
   TextEditingController(text: '');
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Personal Information'),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:  [
                    SizedBox(height: 24,),
                    InfoField(
                      label: 'Full Name',
                      controller: name,
                    ),
                    SizedBox(height: 20,),
                    InfoField(
                      label: 'Organisation',
                      controller: org,
                    ),
                    SizedBox(height: 20,),
                    InfoField(
                      label: 'Role',
                      controller: jobRole,
                      hint: 'Job Title / Role',
                    ),
                    SizedBox(height: 20,),
                    InfoField(
                      label: 'Email',
                      controller: email,
                    ),
                    SizedBox(height: 20,),
                    PhoneField(),
                    InfoField(
                      label: 'Zip Code',
                      controller: zipCode,
                      hint: '000000',
                    ),
                    SizedBox(height: 20,),
                    CommonDropdownField(
                      label: 'Country',
                      hint: 'Select Country',
                      controller: country,
                    ),

                    SizedBox(height: 20,),
                    CommonDropdownField(
                      label: 'City',
                      hint: 'Select City',
                      controller: city,
                    ),

                    SizedBox(height: 20,),
                    InfoField(
                      label: 'Business Address',
                      hint: 'Enter Business Address',
                      controller: address,
                      maxLines: 2,
                    ),
                    CustomButton(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 0, vertical: 32),
                      backGroundColor: context.colorScheme.elevation1,
                      enabled: ValueNotifier(true),
                      onPressed: (){

                      },
                      buttonText:'Edit Personal Information',
                    ),

                  ],
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}
