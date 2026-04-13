import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/passcode/widgets/number_pad.dart';
import 'package:fusion_app/features/passcode/widgets/pin_box.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../authentication/presentation/login_page.dart';
import '../dashboard/presentation/pages/home_screen.dart';
class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  String pin = "";
  bool hasError = false;
  String testPin="1234";
  void _addDigit(String digit) {
    if (pin.length >= 4) return;

    setState(() {
      pin += digit;
    });

    if (pin.length == 4) {
      _submit();
    }
  }

  void _deleteDigit() {
    if (pin.isEmpty) return;

    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  void _submit() {
      if(testPin == pin){
        hasError = false;
        // Navigate to the next screen or perform the desired action
        debugPrint("PIN is correct. Proceeding...");
        showData = true;

          Navigator.pushReplacementNamed(context, Routes.controlPalPage);

      } else {
        hasError = true;
        debugPrint("Incorrect PIN. Please try again.");
      }
      setState(() {});
    debugPrint("Entered PIN: $pin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonAppBar(title: ''),
      body: Column(
        children: [

          const SizedBox(height: 30),

          /// Title
          Text(
            "Enter Passcode",
            style: Theme.of(context).textTheme.h5RegularMobile!.copyWith(
              fontWeight: FontWeight.w400,
              color: context.colorScheme.textPrimary,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 8),

          /// Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "In order to log in securely, please enter the four digit PIN code of the device",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.b3Regular!.copyWith(
                fontWeight: FontWeight.w400,
                color: context.colorScheme.textBody,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// PIN Boxes
          PinBoxes(
            pin: pin,
            hasError: hasError),

           SizedBox(height: hasError ? 40 : 60),

          /// Keypad
          NumberPad(
            onNumber: _addDigit,
            onDelete: _deleteDigit,
            onSubmit: _submit,
          ),

        ],
      ),
    );
  }
}