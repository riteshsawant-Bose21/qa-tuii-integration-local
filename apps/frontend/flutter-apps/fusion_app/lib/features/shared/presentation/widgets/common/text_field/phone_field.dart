import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:fusion_lib/fusion_lib.dart';

class PhoneField extends StatelessWidget {
  const PhoneField({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: context.textTheme.l1Medium!.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          dropdownIconPosition:IconPosition.trailing,
          dropdownIcon: Icon(Icons.keyboard_arrow_down,color: context.colorScheme.textPrimary),
          showCountryFlag: false,
          cursorColor:  context.colorScheme.primaryWhite,
          flagsButtonPadding: EdgeInsetsGeometry.only(left: 10),
          pickerDialogStyle: PickerDialogStyle(
              backgroundColor: context.colorScheme.elevation1,
              listTilePadding: EdgeInsets.symmetric(vertical: 1),
              listTileDivider: CommonDivider()
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: _inputDecoration(
            'Phone Number',
            context,
          ),
          initialCountryCode: 'IN',
          onChanged: (phone) {
            print(phone.completeNumber);
          },
        )
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint,BuildContext context) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.colorScheme.textPlaceholder,
      ),

      filled: true,
      fillColor: context.colorScheme.primaryBlack,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:  BorderSide(
          color:context.colorScheme.strokeLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:  BorderSide(
          color:  context.colorScheme.primary,
        ),
      ),
    );
  }

}

