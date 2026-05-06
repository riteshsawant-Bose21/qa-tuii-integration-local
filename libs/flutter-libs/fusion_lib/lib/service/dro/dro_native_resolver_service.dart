import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Bind the C function signatures
typedef FusionDroSolveNative = Pointer<Utf8> Function(Pointer<Utf8> input);
typedef FusionDroSolveDart = Pointer<Utf8> Function(Pointer<Utf8> input);

typedef FusionDroFreeResultNative = Void Function(Pointer<Utf8> result);
typedef FusionDroFreeResultDart = void Function(Pointer<Utf8> result);

class FusionDro {
  late final DynamicLibrary _lib;
  late final FusionDroSolveDart _solve;
  late final FusionDroFreeResultDart _freeResult;

  FusionDro() {
    _lib = DynamicLibrary.open('libfusion-dsp-resource-optimizer.dylib');

    _solve = _lib.lookup<NativeFunction<FusionDroSolveNative>>('fusion_dro_solve').asFunction();

    _freeResult = _lib.lookup<NativeFunction<FusionDroFreeResultNative>>('fusion_dro_free_result').asFunction();
  }

  /// Pass a JSON string, get back a JSON result string.
  String solve(String jsonInput) {
    final inputPtr = jsonInput.toNativeUtf8();
    final resultPtr = _solve(inputPtr);
    malloc.free(inputPtr);

    if (resultPtr == nullptr) {
      throw Exception('fusion_dro_solve returned NULL (catastrophic failure)');
    }

    final resultJson = resultPtr.toDartString();
    _freeResult(resultPtr);
    return resultJson;
  }
}
