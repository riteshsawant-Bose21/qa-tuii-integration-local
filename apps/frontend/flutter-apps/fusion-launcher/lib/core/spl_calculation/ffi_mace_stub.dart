// File: lib/core/ffi_mace_stub.dart
class MaceEngine {
  static Future<MaceEngine> create() async => throw UnsupportedError('FFI is not supported on this platform.');
  void dispose() => throw UnsupportedError('FFI is not supported on this platform.');
  void clear() => throw UnsupportedError('FFI is not supported on this platform.');

  int addSurface(List<List<double>> vertices) => throw UnsupportedError('FFI is not supported on this platform.');
  int addSpeaker(
    String sku,
    double x,
    double y,
    double z,
    double gain,
    double roll,
    double pitch,
    double yaw,
  ) => throw UnsupportedError('FFI is not supported on this platform.');
  int addFieldPoints(List<List<double>> points) => throw UnsupportedError('FFI is not supported on this platform.');

  int createMeasurement(int type) => throw UnsupportedError('FFI is not supported on this platform.');
  int createGroup() => throw UnsupportedError('FFI is not supported on this platform.');
  void addToGroup(int groupId, int sourceId, int fieldPointsId) => throw UnsupportedError('FFI is not supported on this platform.');
  void addGroupsToMeasurement(int measId, int groupId) => throw UnsupportedError('FFI is not supported on this platform.');
  void runCalculation() => throw UnsupportedError('FFI is not supported on this platform.');
  List<double> getSpl(int fph, int freqHz, int numPoints) => throw UnsupportedError('FFI is not supported on this platform.');
  void debugSpeakers() => throw UnsupportedError('FFI is not supported on this platform.');

  List<double> getSplForBandwidth(int fph, int freqHz, int numPoints) => throw UnsupportedError('FFI is not supported on this platform.');
  Map<String, dynamic> getAllSplJson(int fph) => throw UnsupportedError('FFI is not supported on this platform.');
  List<double> getSplAt(int fph, int bandwidth, double freqHz, int pointCount) => throw UnsupportedError('FFI is not supported on this platform.');
}
