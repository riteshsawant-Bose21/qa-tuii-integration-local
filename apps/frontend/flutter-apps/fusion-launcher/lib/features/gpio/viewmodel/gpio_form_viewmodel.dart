import 'package:flutter/material.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/gpio/gpio_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';

import 'gpio_viewmodel.dart';

class GpioFormViewModel extends ChangeNotifier {
  GpioFormViewModel({required this.viewModel, required this.initial}) {
    // initialize from initial if provided
    if (initial != null) {
      name.text = initial!.name;
      direction = initial!.direction;
      gpiAction = initial!.gpiAction;
      gpoAction = initial!.gpoAction;
      invert = initial!.invert;
      status = initial!.status;
    }
    // load actions from project
    _gpiActions = viewModel.projectViewModel.getGPIActions();
    _gpoActions = viewModel.projectViewModel.getGPOActions();
    name.addListener(() {
      notifyListeners();
    });
  }

  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();

  final GpioViewmodel viewModel;
  final GpioConfig? initial;

  GpioDirection _direction = GpioDirection.input;
  GpioDirection get direction => _direction;
  set direction(GpioDirection value) {
    _direction = value;
    // clear opposite action when switching
    if (value == GpioDirection.input) {
      _gpoAction = null;
    } else {
      _gpiAction = null;
    }
    notifyListeners();
  }

  GpiAction? _gpiAction;
  GpiAction? get gpiAction => _gpiAction;
  set gpiAction(GpiAction? value) {
    _gpiAction = value;
    notifyListeners();
  }

  GpoAction? _gpoAction;
  GpoAction? get gpoAction => _gpoAction;
  set gpoAction(GpoAction? value) {
    _gpoAction = value;
    notifyListeners();
  }

  bool _invert = false;
  bool get invert => _invert;
  set invert(bool value) {
    _invert = value;
    notifyListeners();
  }

  bool _status = false;
  bool get status => _status;
  set status(bool value) {
    _status = value;
    notifyListeners();
  }

  List<GpiAction> _gpiActions = <GpiAction>[];
  List<GpiAction> get gpiActions => _gpiActions;

  List<GpoAction> _gpoActions = <GpoAction>[];
  List<GpoAction> get gpoActions => _gpoActions;

  bool get canEnableSubmit {
    if (name.text.isEmpty) return false;
    if (direction == GpioDirection.input) {
      return gpiAction != null;
    } else {
      return gpoAction != null;
    }
  }

  Future<bool> submit() async {
    if (!key.currentState!.validate()) {
      return false;
    }

    final GpioConfig config = GpioConfig(
      id: initial?.id,
      name: name.text,
      direction: direction,
      gpiAction: direction == GpioDirection.input ? gpiAction : null,
      gpoAction: direction == GpioDirection.output ? gpoAction : null,
      invert: invert,
      status: status,
    );

    try {
      if (initial == null) {
        viewModel.projectViewModel.addGPIOConfig(config: config);
      } else {
        viewModel.projectViewModel.updateGPIOConfig(config: config);
      }
      // refresh the list in parent cubit
      viewModel.refresh();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
