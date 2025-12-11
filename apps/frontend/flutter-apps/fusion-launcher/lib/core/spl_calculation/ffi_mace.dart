import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'base_mace_engine.dart';
import 'ffi_constants.dart';

/// Mace Engine Factory
Future<MaceEngine> createMaceEngine({required String basePath, required String bsfBasePath}) => MaceEngine.create(basePath: basePath, bsfBasePath: bsfBasePath);

/// Load the dylib from the app bundle’s Frameworks folder
late DynamicLibrary _mace;
// Cache base path for locating bundled assets without relying on rootBundle in isolates
String? _bundleBasePath;
void _maceInitializer(String basePath) {
  if (Platform.isMacOS) {
    // return DynamicLibrary.process();
    // On macOS we bundled a fat dylib into MyApp.app/Contents/Frameworks/
    // final String exe = Platform.resolvedExecutable;
    // final String bundleContents = File(exe).parent.parent.path;

    final String bundleContents = basePath;
    _bundleBasePath = bundleContents;
    final String frameworksDir = p.join(bundleContents, 'Frameworks');
    _mace = DynamicLibrary.open(p.join(frameworksDir, 'libMaceAPI.dylib'));
  } else if (Platform.isIOS) {
    _mace = DynamicLibrary.process();
  } else if (Platform.isWindows) {
    // final String exe = Platform.resolvedExecutable;
    // final String exeDir = File(exe).parent.path;
    final String exeDir = basePath;
    final String dllPath = p.join(exeDir, 'MaceAPI.dll');

    debugPrint('DLL path: $dllPath');
    debugPrint('DLL exists: ${File(dllPath).existsSync()}');

    _bundleBasePath = exeDir;
    _mace = DynamicLibrary.open(dllPath);
  } else {
    throw UnsupportedError('This platform is not supported');
  }

  maceCreateEngine = _mace.lookup<NativeFunction<CreateEngine>>('mace_create_engine').asFunction();
  maceDestroyEngine = _mace.lookup<NativeFunction<DestroyEngine>>('mace_destroy_engine').asFunction();
  maceAddPolygon = _mace.lookup<NativeFunction<AddPolygon>>('mace_add_polygon').asFunction();
  maceAddSpeakerCluster = _mace.lookup<NativeFunction<AddSpeakerCluster>>('mace_add_speaker_cluster').asFunction();
  maceAddFieldPoints = _mace.lookup<NativeFunction<AddFieldPoints>>('mace_add_field_points').asFunction();
  maceCreateMeasurement = _mace.lookup<NativeFunction<CreateMeasurement>>('mace_create_measurement').asFunction();
  maceCreateGroup = _mace.lookup<NativeFunction<CreateGroup>>('mace_create_group').asFunction();
  maceAddToGroup = _mace.lookup<NativeFunction<AddToGroup>>('mace_add_to_group').asFunction();
  maceAddGroupsToMeasurement =
      _mace
          .lookup<NativeFunction<AddGroupsToMeasurement>>(
            'mace_add_groups_to_measurement',
          )
          .asFunction();
  maceRunCalc = _mace.lookup<NativeFunction<RunCalculation>>('mace_run_calculation').asFunction();
  maceGetSpl = _mace.lookup<NativeFunction<GetSpl>>('mace_get_spl').asFunction();
  _maceGetAllSplJson = _mace.lookup<NativeFunction<GetAllSplJsonNative>>('mace_get_all_spl_json').asFunction<GetAllSplJsonDart>();
  maceDebugSpeakers = _mace.lookup<NativeFunction<DebugSpeakers>>('mace_debug_speakers').asFunction();
  maceGetSplAt = _mace.lookup<NativeFunction<GetSplAt>>('mace_get_spl_at').asFunction();
  maceClear = _mace.lookup<NativeFunction<Clear>>('mace_clear').asFunction();
}

/// FFI type definitions
typedef CreateEngine = Uint64 Function(Pointer<Utf8>);
typedef DartCreateEngine = int Function(Pointer<Utf8>);

typedef DestroyEngine = Void Function();
typedef DartDestroyEngine = void Function();

typedef AddPolygon = Uint64 Function(Uint64, Pointer<Double>, Int32);
typedef DartAddPolygon = int Function(int, Pointer<Double>, int);

typedef AddSpeakerCluster =
    Uint64 Function(
      Uint64,
      Pointer<Utf8>,
      Double,
      Double,
      Double,
      Double,
      Double,
      Double,
      Double,
    );
typedef DartAddSpeakerCluster =
    int Function(
      int,
      Pointer<Utf8>,
      double,
      double,
      double,
      double,
      double,
      double,
      double,
    );

typedef AddFieldPoints = Uint64 Function(Uint64, Pointer<Double>, Int32);
typedef DartAddFieldPoints = int Function(int, Pointer<Double>, int);

typedef CreateMeasurement = Uint64 Function(Int32);
typedef DartCreateMeasurement = int Function(int);

typedef CreateGroup = Uint64 Function();
typedef DartCreateGroup = int Function();

typedef AddToGroup = Void Function(Uint64, Uint64, Uint64);
typedef DartAddToGroup = void Function(int, int, int);

typedef AddGroupsToMeasurement = Void Function(Uint64, Uint64);
typedef DartAddGroupsToMeasurement = void Function(int, int);

typedef RunCalculation = Void Function(Uint64);
typedef DartRunCalc = void Function(int);

typedef GetSpl = Int32 Function(Uint64, Uint64, Pointer<Double>, Int32);
typedef DartGetSpl = int Function(int, int, Pointer<Double>, int);

typedef GetAllSplJsonNative = Pointer<Utf8> Function(Uint64, Uint64);
typedef GetAllSplJsonDart = Pointer<Utf8> Function(int, int);

typedef GetSplAt =
    Int32 Function(
      Uint64,
      Uint64,
      Int32,
      Double,
      Pointer<Double>,
      Pointer<Double>,
      Pointer<Utf8>,
    );
typedef DartGetSplAt =
    int Function(
      int,
      int,
      int,
      double,
      Pointer<Double>,
      Pointer<Double>,
      Pointer<Utf8>,
    );

typedef DebugSpeakers = Void Function();
typedef DartDebugSpeakers = void Function();

typedef Clear = Void Function(Uint64);
typedef DartClear = void Function(int);

/// Lookup the C functions
late DartCreateEngine maceCreateEngine;
late DartDestroyEngine maceDestroyEngine;
late DartAddPolygon maceAddPolygon;
late DartAddSpeakerCluster maceAddSpeakerCluster;
late DartAddFieldPoints maceAddFieldPoints;
late DartCreateMeasurement maceCreateMeasurement;
late DartCreateGroup maceCreateGroup;
late DartAddToGroup maceAddToGroup;
late DartAddGroupsToMeasurement maceAddGroupsToMeasurement;
late DartRunCalc maceRunCalc;
late DartGetSpl maceGetSpl;
late GetAllSplJsonDart _maceGetAllSplJson;
late DartDebugSpeakers maceDebugSpeakers;
late DartGetSplAt maceGetSplAt;
late DartClear maceClear;

/// Copy .bsf assets into the macOS sandbox and return that folder path
Future<String> prepareLoudspeakersFolder(String supportDirPath) async {
  // final Directory supportDir = await getApplicationSupportDirectory();
  final Directory lsDir = Directory(p.join(supportDirPath, 'Loudspeakers'));
  if (!await lsDir.exists()) {
    await lsDir.create(recursive: true);
  }

  const List<String> bsfs = <String>[
    'assets/Loudspeakers/CO-12 H120.bsf',
    'assets/Loudspeakers/DM2C-LP 100V.bsf',
    'assets/Loudspeakers/DM2C-LP 70V.bsf',
    'assets/Loudspeakers/DM2C-LP.bsf',
    'assets/Loudspeakers/DM3C 100V.bsf',
    'assets/Loudspeakers/DM3C 70V.bsf',
    'assets/Loudspeakers/DM3C.bsf',
    'assets/Loudspeakers/DM3P 100V.bsf',
    'assets/Loudspeakers/DM3P 70V.bsf',
    'assets/Loudspeakers/DM3P.bsf',
    'assets/Loudspeakers/DM3SE 100V.bsf',
    'assets/Loudspeakers/DM3SE 70V.bsf',
    'assets/Loudspeakers/DM3SE.bsf',
    'assets/Loudspeakers/DM5C 100V.bsf',
    'assets/Loudspeakers/DM5C 70V.bsf',
    'assets/Loudspeakers/DM5C.bsf',
    'assets/Loudspeakers/DM5P 100V.bsf',
    'assets/Loudspeakers/DM5P 70V.bsf',
    'assets/Loudspeakers/DM5P.bsf',
    'assets/Loudspeakers/DM5SE 100V.bsf',
    'assets/Loudspeakers/DM5SE 70V.bsf',
    'assets/Loudspeakers/DM5SE.bsf',
    'assets/Loudspeakers/DM6C 100V.bsf',
    'assets/Loudspeakers/DM6C 70V.bsf',
    'assets/Loudspeakers/DM6C.bsf',
    'assets/Loudspeakers/DM6PE 100V.bsf',
    'assets/Loudspeakers/DM6PE 70V.bsf',
    'assets/Loudspeakers/DM6PE.bsf',
    'assets/Loudspeakers/DM6SE 100V.bsf',
    'assets/Loudspeakers/DM6SE 70V.bsf',
    'assets/Loudspeakers/DM6SE.bsf',
    'assets/Loudspeakers/DM8C 100V.bsf',
    'assets/Loudspeakers/DM8C 70V.bsf',
    'assets/Loudspeakers/DM8C.bsf',
    'assets/Loudspeakers/DM8S 100V.bsf',
    'assets/Loudspeakers/DM8S 70V.bsf',
    'assets/Loudspeakers/DM8S.bsf',
    'assets/Loudspeakers/msa_ohs.bsf',
    'assets/Loudspeakers/msa_tb.bsf',
    'assets/Loudspeakers/MSA12X.bsf',
  ];

  // Determine on-disk Flutter assets location to avoid rootBundle in isolates
  String? assetsRoot;
  try {
    // macOS: <bundle>/Frameworks/App.framework/Resources/flutter_assets
    if (Platform.isMacOS && _bundleBasePath != null) {
      assetsRoot = p.join(_bundleBasePath!, 'Frameworks', 'App.framework', 'Resources', 'flutter_assets');
    }
    // Windows desktop: assets copied near exe at data/flutter_assets (typical structure)
    else if (Platform.isWindows && _bundleBasePath != null) {
      // Try common locations used by Flutter desktop
      final String candidate1 = p.join(_bundleBasePath!, 'data', 'flutter_assets');
      final String candidate2 = p.join(_bundleBasePath!, 'flutter_assets');
      if (Directory(candidate1).existsSync()) {
        assetsRoot = candidate1;
      } else if (Directory(candidate2).existsSync()) {
        assetsRoot = candidate2;
      }
    }
  } catch (_) {
    // ignore; we'll fallback to rootBundle
  }

  for (final String assetPath in bsfs) {
    final String filename = p.basename(assetPath); // e.g. "MSA12X.bsf"
    final File outFile = File(p.join(lsDir.path, filename));
    if (await outFile.exists()) {
      // Already copied
      continue;
    }

    // Prefer copying from disk when assetsRoot is known
    if (assetsRoot != null) {
      final String srcPath = p.join(assetsRoot, assetPath);
      final File srcFile = File(srcPath);
      if (await srcFile.exists()) {
        await srcFile.copy(outFile.path);
        continue;
      }
    }

    // Fallback: use rootBundle if available in this isolate
    try {
      final ByteData data = await rootBundle.load(assetPath);
      await outFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    } catch (e) {
      // If both disk copy and rootBundle fail, surface a helpful error once
      throw Exception('Failed to prepare loudspeaker asset "$filename". Checked disk (assetsRoot=$assetsRoot) and rootBundle. Error: $e');
    }
  }

  return lsDir.path;
}

/// High-level Dart wrapper
class MaceEngine extends BaseMaceEngine {
  final int _handle;
  MaceEngine._(this._handle);

  /// Create the engine, copying speaker files into place first.
  static Future<MaceEngine> create({required String basePath, required String bsfBasePath}) async {
    /// Initialize the MACE library
    _maceInitializer(basePath);
    final String speakerDir = await prepareLoudspeakersFolder(bsfBasePath);
    final Pointer<Utf8> ptr = speakerDir.toNativeUtf8();
    final int h = maceCreateEngine(ptr);
    calloc.free(ptr);
    return MaceEngine._(h);
  }

  static Future<String> getLibPath() async {
    if (Platform.isMacOS) {
      // return DynamicLibrary.process();
      // On macOS we bundled a fat dylib into MyApp.app/Contents/Frameworks/
      final String exe = Platform.resolvedExecutable;
      final String bundleContents = File(exe).parent.parent.path;
      return bundleContents;
    } else if (Platform.isIOS) {
      return "";
    } else if (Platform.isWindows) {
      final String exe = Platform.resolvedExecutable;
      final String exeDir = File(exe).parent.path;
      // final String dllPath = p.join(exeDir, 'MaceAPI.dll');

      // print('DLL path: $dllPath');
      // print('DLL exists: ${File(dllPath).existsSync()}');

      return exeDir;
    }
    return "";
  }

  /// Stops & destroys the engine.
  @override
  void dispose() => maceDestroyEngine();

  /// Clears all previously added surfaces/clusters/measurements.
  @override
  void clear() => maceClear(_handle);

  /// Adds a polygon; [vertices] is a list of [x,y,z] triples.
  @override
  int addSurface(List<List<num>> vertices) {
    final List<double> flat = vertices.expand((List<num> r) => r.map((num e) => e.toDouble())).toList();
    final Pointer<Double> ptr = calloc<Double>(flat.length);
    for (int i = 0; i < flat.length; i++) {
      ptr[i] = flat[i];
    }
    final int id = maceAddPolygon(_handle, ptr, vertices.length);
    calloc.free(ptr);
    return id;
  }

  /// Adds a speaker cluster by model name.
  @override
  int addSpeaker(
    String name,
    double x,
    double y,
    double z,
    double gain,
    double roll,
    double pitch,
    double yaw,
  ) {
    final Pointer<Utf8> namePtr = name.toNativeUtf8();
    final int id = maceAddSpeakerCluster(
      _handle,
      namePtr,
      x,
      y,
      z,
      gain,
      roll,
      pitch,
      yaw,
    );
    calloc.free(namePtr);
    return id;
  }

  /// Adds field points; [pts] is a list of [x,y,z] triples.
  @override
  int addFieldPoints(List<List<num>> pts) {
    final List<double> flat = pts.expand((List<num> r) => r.map((num e) => e.toDouble())).toList();
    final Pointer<Double> ptr = calloc<Double>(flat.length);
    for (int i = 0; i < flat.length; i++) {
      ptr[i] = flat[i];
    }
    final int id = maceAddFieldPoints(_handle, ptr, pts.length);
    calloc.free(ptr);
    return id;
  }

  /// Creates a measurement of the given type enum value.
  @override
  int createMeasurement(int type) => maceCreateMeasurement(type);

  /// Creates a new group.
  @override
  int createGroup() => maceCreateGroup();

  /// Adds cluster and fieldPoints to the group.
  @override
  void addToGroup(int groupId, int sourceId, int fieldPointsId) => maceAddToGroup(groupId, sourceId, fieldPointsId);

  /// Associates group with measurement.
  @override
  void addGroupsToMeasurement(int measId, int groupId) => maceAddGroupsToMeasurement(measId, groupId);

  /// Runs the acoustic calculation synchronously.
  @override
  void runCalculation() => maceRunCalc(_handle);

  /// Retrieves SPL levels at [freqHz] for [numPoints].
  @override
  List<double> getSpl(int fph, int freqHz, int numPoints) {
    final Pointer<Double> out = calloc<Double>(numPoints);
    final int count = maceGetSpl(_handle, fph, out, freqHz);
    final List<double> res = List<double>.generate(count, (int i) => out[i]);
    calloc.free(out);

    //getAllSplJson(fph); and print the result for debugging
    final Map<String, dynamic> splJson = getAllSplJson(fph);
    debugPrint('ALL SPL JSON: $splJson');

    return res;
  }

  /// Run MACE calculation and get all SPL data as JSON
  void runSplCalculation(int fph) {
    runCalculation();
  }

  /// Run calculation and extract SPL values for a given bandwidth + frequency.
  /// Returns one value per field point.
  @override
  List<double> getSplForBandwidth(
    int fph,
    Bandwidth bw, {
    int? freqHz, // only required for oneThirdOctave and oneOctave
  }) {
    // Pull JSON from native
    final Map<String, dynamic> json = getAllSplJson(fph);

    // Fix: Properly cast dynamic list to num list, then to int list
    final List<int> freqs = (json['frequencies'] as List<dynamic>).map((dynamic e) => (e as num).toInt()).toList();

    switch (bw) {
      case Bandwidth.oneThirdOctave:
      case Bandwidth.oneOctave:
        if (freqHz == null) {
          throw ArgumentError('freqHz must be provided for $bw');
        }
        final int idx = freqs.indexOf(freqHz);
        if (idx == -1) {
          throw ArgumentError('Frequency $freqHz Hz not available in data');
        }

        // Fix: Correctly parse the matrix structure
        final List<List<double>> mat =
            (json['spl'][bw == Bandwidth.oneThirdOctave ? 'oneThirdOctave' : 'oneOctave'] as List<dynamic>)
                .map<List<double>>(
                  (dynamic row) => (row as List<dynamic>).cast<num>().map((num e) => e.toDouble()).toList(),
                )
                .toList();

        return List<double>.generate(mat.length, (int p) => mat[p][idx]);

      case Bandwidth.vocalBands:
        return (json['spl']['vocalBands'] as List<dynamic>).map((dynamic e) => (e as num).toDouble()).toList();

      case Bandwidth.allBands:
        return (json['spl']['broadband'] as List<dynamic>).map((dynamic e) => (e as num).toDouble()).toList();
    }
  }

  @override
  Map<String, dynamic> getAllSplJson(int fph) {
    final Pointer<Utf8> splJson = _maceGetAllSplJson(_handle, fph);
    final String jsonStr = splJson.toDartString();
    calloc.free(splJson);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  @override
  List<double> getSplAt(
    int fph,
    int bandwidth,
    double freqHz,
    int pointCount,
    String weighting,
  ) {
    final Pointer<Double> out = calloc<Double>(pointCount);
    final Pointer<Double> act = calloc<Double>(1);
    try {
      final int n = maceGetSplAt(
        _handle,
        fph,
        bandwidth,
        freqHz,
        out,
        act,
        weighting.toNativeUtf8(),
      );
      //final double usedHz = act.value; // show in UI if you want
      final List<double> list = List<double>.generate(n, (int i) => out[i]);
      // Optionally: return usedHz too (tuple)
      return list;
    } finally {
      calloc.free(out);
      calloc.free(act);
    }
  }

  /// Prints loaded speaker models (debug).
  @override
  void debugSpeakers() => maceDebugSpeakers();
}
