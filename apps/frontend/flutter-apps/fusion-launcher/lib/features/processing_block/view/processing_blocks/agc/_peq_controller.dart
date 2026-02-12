part of 'agc_block.dart';

enum _BandType {
  peq('peq', 'Peq'),
  highShelf('highShelf', 'High Shelf'),
  lowShelf('lowShelf', 'Low Shelf'),
  notch('notch', 'Notch'),
  lowPass('lpf', 'Low Pass'),
  highPass('hpf', 'High Pass');

  const _BandType(this.value, this.label);
  final String value;
  final String label;
}

enum _CutType {
  sixDbOct(-6, '-6 dB/Oct'),
  twelveDbOct(-12, '-12 dB/Oct');

  const _CutType(this.value, this.label);
  final num value;
  final String label;
}

class _PEQDataPoint {
  final String type;
  final num frequency;
  final num q;
  final num gain;
  final bool bypass;

  _PEQDataPoint({
    required this.type,
    required this.frequency,
    required this.q,
    required this.gain,
    required this.bypass,
  });

  _BandType get bandType => _BandType.values.firstWhere((_BandType e) => e.value == type);

  bool get isGainDisabled => bandType == _BandType.notch;
  bool get isGainDropdown => bandType == _BandType.highPass || bandType == _BandType.lowPass;

  bool get isQDisabled => bandType == _BandType.highPass || bandType == _BandType.lowPass || bandType == _BandType.highShelf || bandType == _BandType.lowShelf;

  _CutType? get cutType => _CutType.values.firstWhereOrNull((_CutType e) => e.value == gain);
}

class AgcController {
  final AlgorithmDataViewmodel valueHandler;

  AgcController(this.valueHandler) {
    if (frequencyProperties.length < 3) {
      // Initialize with 3 bands if less than 3 bands exist
      for (int i = frequencyProperties.length; i < 3; i++) {
        addBand();
      }
    }
  }

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
    if (bands.length >= 16) {
      return;
    }
    final int newBandIndex = bandCount;
    valueHandler.addProperty(PropertySetting(name: 'type', value: 'peq', dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'frequency', value: 1000.0, dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'gain', value: 0.0, dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'q', value: 1.0, dimension: newBandIndex));
    valueHandler.addProperty(PropertySetting(name: 'bypass', value: false, dimension: newBandIndex));
  }

  void removeBand(int bandIndex) {
    if (bands.length <= 3) {
      return;
    }
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

  void sortBandsByFrequency() {
    final List<_PEQDataPoint> tableData = tableMappedData;
    tableData.sort((_PEQDataPoint a, _PEQDataPoint b) => a.frequency.compareTo(b.frequency));

    for (int newIndex = 0; newIndex < tableData.length; newIndex++) {
      final _PEQDataPoint bandData = tableData[newIndex];
      final int newBandIndex = newIndex;
      valueHandler.addProperty(PropertySetting(name: 'type', value: bandData.type, dimension: newBandIndex));
      valueHandler.addProperty(PropertySetting(name: 'frequency', value: bandData.frequency, dimension: newBandIndex));
      valueHandler.addProperty(PropertySetting(name: 'gain', value: bandData.gain, dimension: newBandIndex));
      valueHandler.addProperty(PropertySetting(name: 'q', value: bandData.q, dimension: newBandIndex));
      valueHandler.addProperty(PropertySetting(name: 'bypass', value: bandData.bypass, dimension: newBandIndex));
    }
  }

  void bypassGlobally(bool value) {
    valueHandler.updateValue(field: 'bypass', value: value);
  }

  bool get isGloballyBypassed {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass' && e.dimension == null)?.value == true;
  }

  void toggleQAndBw(bool value) {
    valueHandler.updateValue(field: 'is_in_bw', value: value);
    if (value) {
      final List<PropertySetting> allQValues = allProperties.where((PropertySetting e) => e.name == 'q').toList();
      for (final PropertySetting qProperty in allQValues) {
        final double qValue = qProperty.value?.toDouble();
        final double bwValue = qToBw(qValue);
        valueHandler.updateValue(field: 'q', dimension: qProperty.dimension, value: bwValue);
      }
    } else {
      final List<PropertySetting> allBWValues = allProperties.where((PropertySetting e) => e.name == 'q').toList();
      for (final PropertySetting bwProperty in allBWValues) {
        final double bwValue = bwProperty.value?.toDouble();
        final num qValue = bwToQ(bwValue);
        valueHandler.updateValue(field: 'q', dimension: bwProperty.dimension, value: qValue);
      }
    }
  }

  bool get isInBW {
    return allProperties.firstWhereOrNull((PropertySetting e) => e.name == 'is_in_bw' && e.dimension == null)?.value == true;
  }

  double qToBw(double q) {
    final num q2 = pow(q, 2);
    final double b = q2 * 2;
    final double c = b + 1;

    final double d = pow(c / q2, 2) / 4 - 1;

    final double e = log10(sqrt(d) + c / b) / 0.301;

    return roundToPrecision(e, 3);
  }

  num bwToQ(double bw) {
    return roundTo2Digits(pow(2.0, bw * 0.5) / (pow(2.0, bw) - 1.0));
  }

  double log10(num x) {
    if (x <= 0) {
      // Handle invalid input for logarithm (e.g., return NaN or throw an error)
      return double.nan;
    }
    return log(x) / ln10;
  }

  ///
  /// Table Mapped Data
  ///
  List<_PEQDataPoint> get tableMappedData {
    final List<_PEQDataPoint> tableData = <_PEQDataPoint>[];
    for (final int bandIndex in bands) {
      final List<PropertySetting> bandProperties = getBandProperties(bandIndex);
      final String type = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'type')?.value ?? 'peq';
      final num frequency = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'frequency')?.value ?? 1000;
      final num q = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'q')?.value ?? 1.0;
      final num gain = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'gain')?.value ?? 0.0;
      final bool bypass = bandProperties.firstWhereOrNull((PropertySetting e) => e.name == 'bypass')?.value ?? false;

      tableData.add(_PEQDataPoint(type: type, frequency: frequency, q: q, gain: gain, bypass: bypass));
    }
    return tableData;
  }

  final _PeqGraphDataMapper graphDataMapper = _PeqGraphDataMapper();

  (List<double>, List<double>) get graphData {
    final List<_PEQDataPoint> tableData = tableMappedData;

    if (isInBW || isGloballyBypassed) {
      final List<_PEQDataPoint> oldTD = tableData.toList();
      for (int i = 0; i < oldTD.length; i++) {
        final _PEQDataPoint oldBand = oldTD[i];
        tableData[i] = _PEQDataPoint(
          type: oldBand.type,
          frequency: oldBand.frequency,
          q: isInBW ? bwToQ(oldBand.q.toDouble()) : oldBand.q,
          gain: oldBand.gain,
          bypass: isGloballyBypassed || oldBand.bypass,
        );
      }
    }
    return graphDataMapper.updateGraph(tableData);
  }

  void updateBandType(int index, String value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'type', dimension: bandIndex, value: value);
    if (value == _BandType.lowPass.value || value == _BandType.highPass.value) {
      // Set gain to -12 for lowPass and highPass
      valueHandler.updateValue(field: 'gain', dimension: bandIndex, value: -6);
    }
  }

  void updateBandFrequency(int index, num value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'frequency', dimension: bandIndex, value: value.round());
  }

  void updateQ(int index, num value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'q', dimension: bandIndex, value: roundTo2Digits(value));
  }

  void updateGain(int index, num value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'gain', dimension: bandIndex, value: roundTo2Digits(value));
  }

  void updateBypass(int index, bool value) {
    final int bandIndex = bands[index];

    valueHandler.updateValue(field: 'bypass', dimension: bandIndex, value: value);
  }

  num roundTo2Digits(num value) {
    return (value * 100).round() / 100;
  }

  void resetAllBands() {
    for (final int bandIndex in bands) {
      valueHandler.updateValue(field: 'type', dimension: bandIndex, value: 'peq');
      valueHandler.updateValue(field: 'frequency', dimension: bandIndex, value: 1000.0);
      valueHandler.updateValue(field: 'gain', dimension: bandIndex, value: 0.0);
      valueHandler.updateValue(field: 'q', dimension: bandIndex, value: 1.0);
      valueHandler.updateValue(field: 'bypass', dimension: bandIndex, value: false);
    }
  }

  void deleteAllBands() {
    final int totalBands = bandCount;
    for (int i = totalBands - 1; i >= 0; i--) {
      removeBand(i);
    }
  }
}

///
/// Graph Data Mapper
///
///
class _PeqGraphDataMapper {
  // Note: You'll need to define or import these types and objects:
  // - BandType enum
  // - CutType enum
  // - Node object with bandCount and property access
  // - ParamEQData class
  // - dataPlotter object

  (List<double>, List<double>) updateGraph(List<_PEQDataPoint> peqData) {
    // Generate logarithmic frequency points from 20Hz to 20kHz
    const int numberOfPoints = 1000;
    const double minFreq = 20.0;
    const double maxFreq = 20000.0;

    final List<double> freqs = List<double>.generate(numberOfPoints, (int i) {
      final double logMin = log(minFreq);
      final double logMax = log(maxFreq);
      final double logFreq = logMin + (logMax - logMin) * i / (numberOfPoints - 1);
      return exp(logFreq);
    });

    final List<double> posY = List<double>.filled(numberOfPoints, 0.0);
    final List<double> posX = List<double>.generate(numberOfPoints, (int index) => index.toDouble());

    for (int bandIdx = 0; bandIdx < peqData.length; bandIdx++) {
      final _PEQDataPoint band = peqData[bandIdx];

      if (band.bypass) {
        continue; // skip bypassed bands
      }

      final _BandType bandType = band.bandType;
      final double bandFreq = band.frequency.toDouble();
      final double bandQ = band.q.toDouble();
      final double bandGain = band.gain.toDouble();

      // For high pass and low pass filters, cut type is derived from gain
      final _CutType bandCut = band.cutType ?? _CutType.twelveDbOct;

      final List<double> bandPosY = _calculateGraph(bandType, bandFreq, bandQ, bandGain, bandCut, freqs);

      for (int idx = 0; idx < numberOfPoints; idx++) {
        posY[idx] += bandPosY[idx];
      }
    }

    return (posX, posY);
  }

  static List<double> _calculateGraph(
    _BandType bandType,
    double bandFreq,
    double bandQ,
    double bandGain,
    _CutType bandCut,
    List<double> freqs,
  ) {
    final int numberOfPoints = freqs.length;
    final List<double> posY = List<double>.filled(numberOfPoints, 0.0);

    const double samplingFreq = 48000.0;

    double a = 0.0;
    double omega = 0.0;
    double sn = 0.0;
    double cs = 0.0;
    double alpha = 0.0;
    double beta = 0.0;

    switch (bandType) {
      case _BandType.peq:
      case _BandType.highShelf:
      case _BandType.lowShelf:
      case _BandType.notch:
        final double dOmegaC = tan(pi * bandFreq / samplingFreq);
        final double dOmegaL = tan(pi * 0.5 * bandFreq / samplingFreq * (sqrt(1.0 / bandQ / bandQ + 4.0) - 1.0 / bandQ));
        final double dOmegaH = dOmegaC * dOmegaC / dOmegaL;
        final double dDgQ = dOmegaC / (dOmegaH - dOmegaL);

        a = pow(10.0, 0.025 * bandGain).toDouble();
        omega = 2.0 * pi * bandFreq / samplingFreq;
        sn = sin(omega);
        cs = cos(omega);
        alpha = sn / (2.0 * dDgQ);
        beta = sqrt(a * a + 1.0 - (a - 1.0) * (a - 1.0));
        break;

      case _BandType.lowPass:
      case _BandType.highPass:
        omega = tan(pi * bandFreq / samplingFreq);
        break;
    }

    double a0 = 0.0;
    double a1 = 0.0;
    double a2 = 0.0;
    double b0 = 0.0;
    double b1 = 0.0;
    double b2 = 0.0;

    switch (bandType) {
      case _BandType.peq:
        a0 = 1.0 + alpha / a;
        a1 = -2.0 * cs;
        a2 = 1.0 - alpha / a;
        b0 = 1.0 + alpha * a;
        b1 = -2.0 * cs;
        b2 = 1.0 - alpha * a;
        break;

      case _BandType.highShelf:
        a0 = a + 1.0 - (a - 1.0) * cs + beta * sn;
        a1 = 2.0 * (a - 1.0 - (a + 1.0) * cs);
        a2 = a + 1.0 - (a - 1.0) * cs - beta * sn;
        b0 = a * (a + 1.0 + (a - 1.0) * cs + beta * sn);
        b1 = -2.0 * a * (a - 1.0 + (a + 1.0) * cs);
        b2 = a * (a + 1.0 + (a - 1.0) * cs - beta * sn);
        break;

      case _BandType.lowShelf:
        a0 = a + 1.0 + (a - 1.0) * cs + beta * sn;
        a1 = -2.0 * (a - 1.0 + (a + 1.0) * cs);
        a2 = a + 1.0 + (a - 1.0) * cs - beta * sn;
        b0 = a * (a + 1.0 - (a - 1.0) * cs + beta * sn);
        b1 = 2.0 * a * (a - 1.0 - (a + 1.0) * cs);
        b2 = a * (a + 1.0 - (a - 1.0) * cs - beta * sn);
        break;

      case _BandType.notch:
        a0 = 1.0 + alpha;
        a1 = -2.0 * cs;
        a2 = 1.0 - alpha;
        b0 = 1.0;
        b1 = -2.0 * cs;
        b2 = 1.0;
        break;

      case _BandType.lowPass:
        switch (bandCut) {
          case _CutType.sixDbOct:
            a0 = 1.0 + omega;
            a1 = omega - 1.0;
            b0 = omega;
            b1 = omega;
            break;

          case _CutType.twelveDbOct:
            a0 = 1.0 + sqrt(2.0) * omega + omega * omega;
            a1 = 2.0 * omega * omega - 2.0;
            a2 = 1.0 - sqrt(2.0) * omega + omega * omega;
            b0 = omega * omega;
            b1 = 2.0 * b0;
            b2 = b0;
            break;
        }
        break;

      case _BandType.highPass:
        switch (bandCut) {
          case _CutType.sixDbOct:
            a0 = 1.0 + omega;
            a1 = omega - 1.0;
            b0 = 1.0;
            b1 = -1.0;
            break;

          case _CutType.twelveDbOct:
            a0 = 1.0 + sqrt(2.0) * omega + omega * omega;
            a1 = 2.0 * omega * omega - 2.0;
            a2 = 1.0 - sqrt(2.0) * omega + omega * omega;
            b0 = 1.0;
            b1 = -2.0;
            b2 = 1.0;
            break;
        }
        break;
    }

    for (int i = 0; i < numberOfPoints; i++) {
      final double currentOmega = 2 * pi * freqs[i] / samplingFreq;
      final double cos1 = cos(currentOmega);
      final double cos2 = cos(2.0 * currentOmega);
      final double sin1 = sin(currentOmega);
      final double sin2 = sin(2.0 * currentOmega);

      double aReal;
      double aImag;
      double bReal;
      double bImag;

      if ((bandType == _BandType.lowPass && bandCut == _CutType.sixDbOct) || (bandType == _BandType.highPass && bandCut == _CutType.sixDbOct)) {
        aReal = a0 + a1 * cos1;
        aImag = a1 * sin1;
        bReal = b0 + b1 * cos1;
        bImag = b1 * sin1;
      } else {
        aReal = a0 + a1 * cos1 + a2 * cos2;
        aImag = a1 * sin1 + a2 * sin2;
        bReal = b0 + b1 * cos1 + b2 * cos2;
        bImag = b1 * sin1 + b2 * sin2;
      }

      final double absA = sqrt(aReal * aReal + aImag * aImag);
      final double absB = sqrt(bReal * bReal + bImag * bImag);
      posY[i] = 20.0 * (log(absB / absA) / ln10);
    }

    return posY;
  }
}
