import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/dropdown_field.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/phone_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../shared/presentation/widgets/common/text_field/info_field.dart';

class AddressInformationScreen extends StatelessWidget {
  AddressInformationScreen({super.key});

  final TextEditingController timezone =
  TextEditingController(text: 'USA(GMT-8)');
  final TextEditingController address1 =
  TextEditingController(text: 'e.g 123,Main Street');

  final TextEditingController address2 =
  TextEditingController(text: 'e.g. Apartment, Suit, Unit, Building');
  final TextEditingController zipcode =
  TextEditingController(text: '94102');
  final TextEditingController city =
  TextEditingController(text: 'San Francisco');
  final TextEditingController state =
  TextEditingController(text: 'California');

  final TextEditingController country =
  TextEditingController(text: 'United States');
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
          backgroundColor: context.colorScheme.primaryBlack,
          appBar: CommonAppBar(title: 'Personal Information'),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomButton(
                backGroundColor: context.colorScheme.elevation1,
                enabled: ValueNotifier(true),
                onPressed: (){

                },
                buttonText:'Edit Personal Information',
              ),
            ],
          ),
          body: Column(
            children: [
              SizedBox(height: 24,),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      InfoField(
                        label: 'Time Zone',
                        controller: timezone,
                      ),
                      SizedBox(height: 20,),
                      InfoField(
                        label: 'Address Line 1',
                        controller: address1,
                      ),
                      SizedBox(height: 20,),
                      InfoField(
                        label: 'Address Line 2',
                        controller: address2,
                        hint: 'Job Title / Role',
                      ),
                      SizedBox(height: 20,),
                      InfoField(
                        label: 'Zip Code',
                        controller: zipcode,
                        hint: '000000',
                      ),

                      SizedBox(height: 20,),
                      CommonDropdownField(
                        label: 'City',
                        hint: 'Select City',
                        controller: city,
                      ),


                      SizedBox(height: 20,),
                      CommonDropdownField(
                        label: 'State',
                        hint: 'Select City',
                        controller: state,
                      ),

                      SizedBox(height: 20,),
                      CommonDropdownField(
                        label: 'Country',
                        hint: 'Select Country',
                        controller: country,
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
