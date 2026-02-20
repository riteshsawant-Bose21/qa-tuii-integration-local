import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:path_provider/path_provider.dart';

import 'ffi_constants.dart';
import 'mace_calculation_manager.dart';
import 'mace_engine_provider.dart';

/// Persistent isolate-based manager that initializes the MACE engine inside the isolate
/// and proxies SPL calculation functions to that isolate.
class IsolatedMaceCalculationManager {
  final Map<int, SPLCalculation> _calcByFph = <int, SPLCalculation>{};

  static final IsolatedMaceCalculationManager instance = IsolatedMaceCalculationManager._();
  IsolatedMaceCalculationManager._();

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final Map<int, Completer<dynamic>> _pending = <int, Completer<dynamic>>{};
  int _reqId = 0;

  bool get isRunning => _isolate != null && _sendPort != null;

  /// Starts the isolate and initializes the MACE engine inside it.
  Future<void> start() async {
    debugPrint('[isolate] start() called');
    if (isRunning) return;

    _receivePort = ReceivePort();
    final Completer<SendPort> handshake = Completer<SendPort>();

    _receivePort!.listen((dynamic msg) {
      if (msg is SendPort && !handshake.isCompleted) {
        // Initial handshake: child sends its SendPort
        handshake.complete(msg);
        return;
      }
      debugPrint('[isolate] Recieved message: $msg');
      if (msg is Map) {
        final int id = msg['id'] as int;
        final bool ok = msg['ok'] as bool? ?? false;
        final dynamic result = msg['result'];
        final dynamic error = msg['error'];
        final Completer<dynamic>? c = _pending.remove(id);
        if (c != null) {
          if (ok) {
            c.complete(result);
          } else {
            c.completeError(error ?? 'Isolate error');
          }
        }
      }
    });

    _isolate = await Isolate.spawn<_IsolateInit>(
      _isolateMain,
      _IsolateInit(mainSendPort: _receivePort!.sendPort),
      debugName: 'MACE_SPL_Isolate',
    );

    _sendPort = await handshake.future;

    // Initialize MACE engine inside isolate
    final String basePath = await MaceEngine.getLibPath();
    debugPrint('[isolate] initializing engine in isolate with basePath=$basePath');
    await _call<void>('initializeEngine', <String, dynamic>{
      'basePath': basePath,
      'bsfBasePath': (await getApplicationSupportDirectory()).path,
    });
    debugPrint('[isolate] start() completed');
  }

  /// Stops the isolate and cleans up resources.
  Future<void> stop() async {
    debugPrint('[isolate] stop() called');
    _sendPort = null;
    _receivePort?.close();
    _receivePort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    for (final Completer<dynamic> c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError('Isolate stopped');
      }
    }
    _pending.clear();
    debugPrint('[isolate] stop() completed');
  }

  Future<T> _call<T>(String method, Map<String, dynamic> args) async {
    debugPrint('[isolate] _call<$T>(method=$method, args=${args.keys.toList()})');
    if (!isRunning) {
      throw StateError('Isolate not running. Call start() first.');
    }
    final int id = ++_reqId;
    final Completer<T> completer = Completer<T>();
    _pending[id] = completer as Completer<dynamic>;
    _sendPort!.send(<String, dynamic>{'id': id, 'method': method, 'args': args});
    return completer.future;
  }

  // Proxy methods
  Future<void> calculateSpl({
    required List<HardwareComponent> speakers,
    required List<ListeningArea> surfaces,
    required double resolutionSpacing,
  }) async {
    _calcByFph.clear();
    debugPrint('[isolate] calculateSpl(speakers=${speakers.length}, surfaces=${surfaces.length}, resolutionSpacing=$resolutionSpacing)');
    await _call<void>('calculateSpl', <String, dynamic>{
      'speakers': speakers,
      'surfaces': surfaces,
      'resolutionSpacing': resolutionSpacing,
    });
    debugPrint('[isolate] calculateSpl() finished');
  }

  Future<List<SPLCalculation>> getSplAt({
    required int fph,
    required Bandwidth bandwidth,
    required double freqHz,
    required Weighting weighting,
    required bool relative,
    required double resolutionSpacing,
  }) async {
    debugPrint(
      '[isolate] getSplAt(fph=$fph, bandwidth=$bandwidth, freqHz=$freqHz, weighting=$weighting, relative=$relative, resolutionSpacing=$resolutionSpacing)',
    );
    final dynamic result = await _call<dynamic>('getSplAt', <String, dynamic>{
      'fph': fph,
      'bandwidth': bandwidth,
      'freqHz': freqHz,
      'weighting': weighting,
      'relative': relative,
      'resolutionSpacing': resolutionSpacing,
    });
    debugPrint("[isolate] Get SPL at returned $result");
    debugPrint('[isolate] getSplAt() returning ${(result as List<dynamic>).length} calculations');
    return (result).cast<SPLCalculation>();
  }

  Future<List<SPLCalculation>> currentCalculations() async {
    debugPrint('[isolate] currentCalculations() called');
    final dynamic result = await _call<dynamic>('currentCalculations', const <String, dynamic>{});
    debugPrint('[isolate] currentCalculations() returning ${(result as List<dynamic>).length} items');
    return (result).cast<SPLCalculation>();
  }

  Future<List<double>> getRelativeSpls(List<double> spls) async {
    debugPrint('[isolate] getRelativeSpls(len=${spls.length})');
    final dynamic result = await _call<dynamic>('getRelativeSpls', <String, dynamic>{'spls': spls});
    debugPrint('[isolate] getRelativeSpls() returning ${(result as List<dynamic>).length} values');
    return (result).cast<double>();
  }
}

// ----- Isolate implementation -----

class _IsolateInit {
  final SendPort mainSendPort;
  _IsolateInit({required this.mainSendPort});
}

void _isolateMain(_IsolateInit init) async {
  final ReceivePort rp = ReceivePort();
  init.mainSendPort.send(rp.sendPort);

  // // Initialize MACE engine inside isolate.
  // // Create engine inside isolate
  // final String basePath = await MaceEngine.getLibPath();
  // final MaceEngine engine = await MaceEngine.create(
  //   basePath: basePath,
  //   bsfBasePath: 'assets/Loudspeakers',
  // );
  late MaceEngine engine;
  await for (final dynamic msg in rp) {
    if (msg is Map) {
      final int id = msg['id'] as int;
      final String method = msg['method'] as String;
      final Map<String, dynamic> args = (msg['args'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

      try {
        switch (method) {
          case 'initializeEngine':
            {
              debugPrint('[isolate] initializeEngine called');
              final String basePath = args['basePath'] as String;
              final String bsfBasePath = args['bsfBasePath'] as String;

              engine = await MaceEngine.create(
                basePath: basePath,
                bsfBasePath: bsfBasePath,
              );
              debugPrint('[isolate] initializeEngine completed');
              init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': true, 'result': null});
              break;
            }
          case 'calculateSpl':
            {
              debugPrint('[isolate] calculateSpl handler called');
              final List<HardwareComponent> speakers = (args['speakers'] as List<dynamic>).cast<HardwareComponent>();
              final List<ListeningArea> surfaces = (args['surfaces'] as List<dynamic>).cast<ListeningArea>();
              final double resolutionSpacing = (args['resolutionSpacing'] as num).toDouble();

              await SPLCalculationManager.calculateSpl(engine, speakers, surfaces, resolutionSpacing);
              debugPrint('[isolate] calculateSpl handler completed');
              init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': true, 'result': null});
              break;
            }
          case 'getSplAt':
            {
              debugPrint('[isolate] getSplAt handler called');
              final int fph = args['fph'] as int;
              final Bandwidth bandwidth = args['bandwidth'] as Bandwidth;
              final double freqHz = (args['freqHz'] as num).toDouble();
              final Weighting weighting = args['weighting'] as Weighting;
              final bool relative = args['relative'] as bool;
              final double resolutionSpacing = (args['resolutionSpacing'] as num).toDouble();

              final List<SPLCalculation> res = SPLCalculationManager.getSplAt(
                engine,
                fph,
                bandwidth,
                freqHz,
                weighting,
                relative,
                resolutionSpacing,
              );
              debugPrint('[isolate] getSplAt handler completed with ${res.length} results');
              init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': true, 'result': res});
              break;
            }
          case 'currentCalculations':
            {
              debugPrint('[isolate] currentCalculations handler called');
              final List<SPLCalculation> res = SPLCalculationManager.currentCalculations().toList();
              debugPrint('[isolate] currentCalculations handler completed with ${res.length} items');
              init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': true, 'result': res});
              break;
            }
          case 'getRelativeSpls':
            {
              debugPrint('[isolate] getRelativeSpls handler called');
              final List<double> spls = (args['spls'] as List<dynamic>).map((dynamic v) => (v as num).toDouble()).toList();
              final List<double> res = _IsolateRelative.relativeSpls(spls);
              debugPrint('[isolate] getRelativeSpls handler completed with ${res.length} values');
              init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': true, 'result': res});
              break;
            }
          default:
            init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': false, 'error': 'Unknown method $method'});
        }
      } catch (e, st) {
        debugPrint('Isolate method $method failed: $e\n$st');
        init.mainSendPort.send(<String, dynamic>{'id': id, 'ok': false, 'error': e.toString()});
      }
    }
  }
}

/// Local helper for pure relative SPL computation in isolate.
class _IsolateRelative {
  static List<double> relativeSpls(List<double> spls) {
    debugPrint('[isolate] relativeSpls(len=${spls.length})');
    if (spls.isEmpty) return const <double>[];

    double sumLin = 0.0;
    int n = 0;
    for (final double v in spls) {
      if (v.isFinite) {
        sumLin += math.pow(10.0, v / 10.0) as double;
        n++;
      }
    }
    if (n == 0) return List<double>.filled(spls.length, 0.0);

    final double avgDb = 10.0 * math.log(sumLin / n) / math.ln10;

    const double window = 6.0;
    final double lo = avgDb - window;
    final double hi = avgDb + window;

    return List<double>.generate(spls.length, (int i) {
      final double v = spls[i];
      final double x = v.isFinite ? v : avgDb;
      return x.clamp(lo, hi);
    });
  }
}
