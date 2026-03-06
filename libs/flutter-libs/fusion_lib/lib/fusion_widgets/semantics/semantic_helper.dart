import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SemanticHelper {
  // Core identifier generator
  static String createTestId(String type, String identifier) {
    final String sanitizedIdentifier = identifier.replaceAll(' ', '_');
    return '${type}_${sanitizedIdentifier.toLowerCase()}';
  }

  // Button elements
  static Widget button({
    required String testId,
    required Widget child,
    bool isActive = true,
    String? label,
    bool? state,
    VoidCallback? ontap,
    bool? selected,
  }) {
    return Semantics(
      identifier: testId,
      button: true,
      onTap: ontap,
      container: true,
      enabled: isActive,
      label: label,
      child: child,
      checked: selected,
    );
  }

  // Container sections with boundary control
  static Widget container({
    required String testId,
    required Widget child,
    bool explicitChildNodes = false,
    String? label,
    String? value,
  }) {
    return Semantics(
      value: value,
      identifier: testId,
      container: true,
      explicitChildNodes: explicitChildNodes,
      label: label,
      child: child,
    );
  }

  static Widget image({
    required String testId,
    required Widget child,
    bool explicitChildNodes = false,
    String? label,
  }) {
    return Semantics(
      identifier: testId,
      image: true,
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
      container: true,
      identifier: testId,
      checked: value,
      label: label,
      excludeSemantics: excludeChildSemantics,
      child: child,
    );
  }

  // Radio controls
  static Widget radio({
    required String testId,
    required bool value,
    required Widget child,
    String? label,
    bool excludeChildSemantics = true,
  }) {
    return Semantics(
      container: true,
      identifier: testId,
      selected: value,
      label: label,
      excludeSemantics: excludeChildSemantics,
      child: child,
    );
  }

  static Widget radioGroup({
    required String testId,
    required Widget child,
    String? label,
  }) {
    return Semantics(
      container: true,
      identifier: testId,
      label: label,
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
    String? value,
  }) {
    return Semantics(
      container: true,
      identifier: testId,
      label: label,
      value: value,
      readOnly: true,
      child: child,
    );
  }

  static Widget textInput({
    required String testId,
    required Widget child,
    String? label,
    bool? readonly,
    bool? enabled,
    bool? focused,
    String? value,
    bool? live,
  }) {
    return Semantics(
      identifier: testId,
      label: label,
      readOnly: readonly,
      enabled: enabled,
      focused: focused,
      value: value,
      child: child,
      liveRegion: live,
    );
  }

  static Widget dropdown({
    required String testId,
    required Widget child,
    String? value,
  }) {
    return Semantics(
      button: true,
      identifier: testId,
      value: value,
      child: child,
    );
  }

  static Widget popupButton({
    required String testId,
    required Widget child,
    bool? enabled,
    bool? blur,
  }) {
    return Semantics(
      button: true,
      identifier: testId,
      enabled: enabled,
      child: child,
      focusable: blur,
    );
  }

  static Widget table({
    required String testId,
    required Widget child,
    bool? enabled,
    bool? blur,
    String? value,
  }) {
    return Semantics(
      button: true,
      identifier: testId,
      enabled: enabled,
      child: child,
      value: value,
      focusable: blur,
    );
  }
}
