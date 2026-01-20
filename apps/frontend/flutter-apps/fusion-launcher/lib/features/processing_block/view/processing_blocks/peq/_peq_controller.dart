part of 'peq_block.dart';

class PEQController {
  final AlgorithmDataViewmodel valueHandler;

  PEQController(this.valueHandler);

  List<PropertySetting> get allProperties {
    return valueHandler.processingBlock.properties;
  }

  List<PropertySetting> get frequencyProperties {
    return allProperties.where((PropertySetting e) => e.name == 'type').toList();
  }

  int get bandCount {
    return frequencyProperties.map((PropertySetting e) => e.dimension).toSet().length;
  }

  List<int> get bands {
    return frequencyProperties.map((PropertySetting e) => e.dimension ?? 0).toSet().toList();
  }

  List<PropertySetting> getBandProperties(int bandIndex) {
    return allProperties.where((PropertySetting e) => e.dimension == bandIndex).toList();
  }

  bool get canDelete {
    return bandCount > 3;
  }

  void addBand() {
    final int newBandIndex = bandCount;
    valueHandler.addProperty(PropertySetting(name: 'type', value: 'peq', dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'frequency', value: 1000.0, dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'gain', value: 0.0, dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'q', value: 1.0, dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'bypass', value: false, dimension: newBandIndex));
  }

  void removeBand(int bandIndex) {
    final int bandToRemove = bands[bandIndex];

    for (final int index in bands) {
      if (index > bandToRemove) {
        final List<PropertySetting> bandProperties = getBandProperties(index);
        for (final PropertySetting property in bandProperties) {
          valueHandler.updateValue(field: property.name, dimension: index - 1, value: property.value);
        }
      }
    }
    final List<PropertySetting> propertiesToRemove = getBandProperties(bands.last);
    for (final PropertySetting property in propertiesToRemove) {
      valueHandler.removeProperty(property);
    }
  }

  double qToBw(double q) {
    final num q2 = pow(q, 2);
    final double b = q2 * 2;
    final double c = b + 1;

    final double d = pow(c / q2, 2) / 4 - 1;

    final double e = log(sqrt(d) + c / b) / 0.301;

    return roundToPrecision(e, 3);
  }

  double bwToQ(double bw) {
    return pow(2.0, bw * 0.5) / (pow(2.0, bw) - 1.0);
  }

  ///
  /// Table Mapped Data
  ///
  List<({String type, num frequency, num q, num gain, bool bypass})> get tableMappedData {
    final List<({String type, num frequency, num q, num gain, bool bypass})> tableData = <({num frequency, num gain, num q, String type, bool bypass})>[];
    for (final int bandIndex in bands) {
      final List<PropertySetting> bandProperties = getBandProperties(bandIndex);
      final String type = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'type')?.value ?? 'peq';
      final num frequency = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'frequency')?.value ?? 1000;
      final num q = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'q')?.value ?? 1.0;
      final num gain = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'gain')?.value ?? 0.0;
      final bool bypass = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass')?.value ?? false;

      tableData.add((type: type, frequency: frequency, q: q, gain: gain, bypass: bypass));
    }
    return tableData;
  }

  void updateBandType(int index, String value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'type', dimension: bandIndex, value: value);
  }

  void updateBandFrequency(int index, num value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'frequency', dimension: bandIndex, value: value);
  }

  void updateQ(int index, num value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'q', dimension: bandIndex, value: value);
  }

  void updateGain(int index, num value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'gain', dimension: bandIndex, value: value);
  }

  void updateBypass(int index, bool value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'bypass', dimension: bandIndex, value: value);
  }
}
