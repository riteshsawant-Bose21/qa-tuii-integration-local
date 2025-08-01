import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_form_field.dart';

class ContactLocationTab extends StatelessWidget {
  final TextEditingController addressLine1Controller;
  final TextEditingController addressLine2Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipCodeController;
  final TextEditingController countryController;
  final TextEditingController timezoneController;

  const ContactLocationTab({
    super.key,
    required this.addressLine1Controller,
    required this.addressLine2Controller,
    required this.cityController,
    required this.stateController,
    required this.zipCodeController,
    required this.countryController,
    required this.timezoneController,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width <= 800 ? double.infinity : MediaQuery.of(context).size.width * 0.5;

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Mailing Address Section
                const Text(
                  'Mailing Address',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                CustomFormField(label: 'Address Line 1', controller: addressLine1Controller, hintText: 'Address Line 1'),
                const SizedBox(height: 24),

                CustomFormField(label: 'Address Line 2', controller: addressLine2Controller, hintText: 'Address Line 2'),
                const SizedBox(height: 24),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomFormField(label: 'City', controller: cityController, hintText: 'City'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomFormField(label: 'State', controller: stateController, hintText: 'State'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: CustomFormField(label: 'Zip Code', controller: zipCodeController, hintText: 'Zip Code'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomFormField(label: 'Country', controller: countryController, hintText: 'Country'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Time Zone Section
                const Text(
                  'Time Zone',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: DropdownButtonFormField<String>(
                    value: 'Boston, MA, USA (GMT-4)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'Boston, MA, USA (GMT-4)',
                        child: Text('Boston, MA, USA (GMT-4)'),
                      ),
                    ],
                    onChanged: (String? value) {},
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
