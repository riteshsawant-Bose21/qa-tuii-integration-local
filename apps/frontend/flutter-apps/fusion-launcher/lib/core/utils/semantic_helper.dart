import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SemanticHelper {
  // Core identifier generator
  static String createTestId(String type, String identifier) {
    final String sanitizedIdentifier = identifier.replaceAll(' ', '_');
    return '${type}_$sanitizedIdentifier';
  }

  // Button elements
  static Widget button({
    required String testId,
    required Widget child,
  }) {
    return Semantics(
      identifier: testId,
      button: true,
      child: child,
    );
  }

  // Container sections with boundary control
  static Widget container({
    required String testId,
    required Widget child,
    bool explicitChildNodes = false,
    String? label,
  }) {
    return Semantics(
      identifier: testId,
      container: true,
      explicitChildNodes: explicitChildNodes,
      label: label,
      child: child,
    );
  }

  // Toggle controls (Switch, Checkbox)
  static Widget toggle({
    required String testId,
    required bool value,
    required Widget child,
    String? label,
    bool excludeChildSemantics = true,
  }) {
    return Semantics(
      identifier: testId,
      toggled: value,
      label: label,
      excludeSemantics: excludeChildSemantics,
      child: child,
    );
  }

  // List items with proper ordering
  static Widget listItem({
    required String testId,
    required Widget child,
    required int index,
    String? label,
  }) {
    return Semantics(
      identifier: testId,
      container: true,
      sortKey: OrdinalSortKey(index.toDouble()),
      label: label,
      child: child,
    );
  }

  // Form controls
  static Widget formControl({
    required String testId,
    required Widget child,
    String? label,
    String? hint,
  }) {
    return Semantics(
      identifier: testId,
      textField: true,
      label: label,
      hint: hint,
      child: child,
    );
  }

  // Static Text
  static Widget staticText({
    required String testId,
    required Widget child,
    String? label,
  }) {
    return Semantics(
      identifier: testId,
      label: label,
      readOnly: true,
      child: child,
    );
  }
}