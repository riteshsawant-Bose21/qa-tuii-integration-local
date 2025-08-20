import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_form_field.dart';

class PreferencesTab extends StatelessWidget {
  final String measurementUnit;
  final String currency;
  final String language;
  final TextEditingController locationController;
  final bool productUpdates;
  final bool projectActivity;
  final bool trainingResources;
  final ValueChanged<String> onMeasurementUnitChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<bool> onProductUpdatesChanged;
  final ValueChanged<bool> onProjectActivityChanged;
  final ValueChanged<bool> onTrainingResourcesChanged;

  const PreferencesTab({
    super.key,
    required this.measurementUnit,
    required this.currency,
    required this.language,
    required this.locationController,
    required this.productUpdates,
    required this.projectActivity,
    required this.trainingResources,
    required this.onMeasurementUnitChanged,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
    required this.onLocationChanged,
    required this.onProductUpdatesChanged,
    required this.onProjectActivityChanged,
    required this.onTrainingResourcesChanged,
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
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionTitle('Measurement Units'),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _customCheckboxTile('Imperial', measurementUnit == 'Imperial', (bool value) {
                      print('Imperial checkbox changed: $value');
                      onMeasurementUnitChanged('Imperial');
                    }),
                    const SizedBox(width: 24),
                    _customCheckboxTile('Metric', measurementUnit == 'Metric', (bool value) {
                      print('Imperial checkbox changed: $value');
                      onMeasurementUnitChanged('Metric');
                    }),
                  ],
                ),
                const SizedBox(height: 32),
                _sectionTitle('Currency'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: currency,
                  items: const <String>['USD', 'EUR', 'GBP'],
                  onChanged: (String? value) {
                    if (value != null) onCurrencyChanged(value);
                  },
                ),
                const SizedBox(height: 24),
                _sectionTitle('Language'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: language,
                  items: const <String>['English (US)', 'English (UK)', 'Spanish'],
                  onChanged: (String? value) {
                    if (value != null) onLanguageChanged(value);
                  },
                ),
                const SizedBox(height: 24),
                CustomFormField(label: 'Location', controller: locationController, hintText: 'Enter your location'),
                const SizedBox(height: 32),
                _sectionTitle('Notifications'),
                const SizedBox(height: 12),
                _customCheckboxTile('Product Updates', productUpdates, onProductUpdatesChanged),
                const SizedBox(height: 16),
                _customCheckboxTile('Project Activity', projectActivity, onProjectActivityChanged),
                const SizedBox(height: 16),
                _customCheckboxTile('Training & Resources', trainingResources, onTrainingResourcesChanged),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _customCheckboxTile(String title, bool value, Function(bool) onChanged) {
    return Row(
      children: <Widget>[
        SizedBox(
          height: 20,
          width: 20,
          child: Checkbox(
            value: value,
            onChanged: (bool? val) => onChanged(val!),
            activeColor: Colors.black, // updated active color to black
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
      ],
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.blue)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        items: items.map((String label) => DropdownMenuItem<String>(value: label, child: Text(label, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
