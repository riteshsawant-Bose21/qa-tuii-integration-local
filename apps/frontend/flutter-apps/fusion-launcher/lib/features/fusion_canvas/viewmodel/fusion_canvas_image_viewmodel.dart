import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/di/service_locator.dart';

import '../../../core/image_loader_service.dart';

class FusionCanvasImageViewModel extends Cubit<Map<String, ui.Image>> {
  FusionCanvasImageViewModel() : super(<String, ui.Image>{});

  void loadImage(
    String key,
  ) async {
    final ImageLoaderService loader = fusionLibLocator<ImageLoaderService>();
    try {
      final ui.Image image = await loader.loadImage(key);
      emit(Map<String, ui.Image>.from(state)..[key] = image);
    } catch (e) {}
  }

  ui.Image? getImage(String key) {
    if (!state.containsKey(key)) {
      loadImage(key);
      return null;
    }
    return state[key];
  }
}
