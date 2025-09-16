/// Controller catalog containing product specifications
/// 
/// This module contains the controller catalog for Bose ControlPal series
/// and other control devices.

import 'controller_types.dart';

/// Controller catalog with all available Fusion controllers
class ControllerCatalog {
  static const List<ControllerSpec> controllers = [
    ControllerSpec(
      name: "ControlPal LT",
      imageUrl: 'assets/images/control_pal.png',
      description: 'Basic volume control with LED display',
      price: 199.99,
    ),
    ControllerSpec(
      name: "ControlPal Pro",
      imageUrl: 'assets/images/control_pal_pro.png',
      description: 'Advanced touch controller with EQ and parameter control',
      price: 299.99,
    ),
  ];

  /// Quick access to specific controllers
  static ControllerSpec get controlPalLt => controllers[0];
  static ControllerSpec get controlPalPro => controllers[1];

  /// Get all controllers from the catalog
  static List<ControllerSpec> getAllControllers() => controllers;

  /// Find controller by name
  static ControllerSpec? findByName(String name) {
    try {
      return controllers.firstWhere((controller) => controller.name == name);
    } catch (e) {
      return null;
    }
  }
}
