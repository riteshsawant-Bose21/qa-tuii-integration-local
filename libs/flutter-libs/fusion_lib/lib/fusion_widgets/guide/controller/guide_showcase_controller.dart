import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GuideShowCaseSteps {
  uploadFloorPlan,
  showFloorPickCalibration,
  confirmFloorCalibrated,
  acousticMode,
  drawListeningArea,
  addSpeakers,
  systemMode,
  systemModeTabs,
  addZone,
  selectListeningArea,
  showListeningAreaSelectionArea,
  confirmSelectListeningArea,
}

//  context.read<GuideShowCaseController>().completeStep();
//  GuideShowcaseWrapper(
//    step: GuideShowCaseSteps.acousticMode,
//    onNextTap: Navigator.of(context).pop,

class GuideShowCaseController extends ChangeNotifier {
  static const String _storageKey = 'is_guide_showcase_step_completed';

  final Set<GuideShowCaseSteps> _completedSteps = <GuideShowCaseSteps>{};
  GuideShowCaseSteps? _currentStep;
  bool _isInitialized = false;
  bool _isGuideCompleted = false;

  GuideShowCaseController() {
    _initialize();
  }

  // Getters
  GuideShowCaseSteps? get currentStep => _currentStep;
  bool get isInitialized => _isInitialized;
  bool get isGuideCompleted => _isGuideCompleted;
  Set<GuideShowCaseSteps> get completedSteps => Set<GuideShowCaseSteps>.unmodifiable(_completedSteps);

  void guideNeeded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _initialize();
  }

  /// Initialize controller and check if guide is already completed
  Future<void> _initialize() async {
    await _loadGuideStatus();
    if (!_isGuideCompleted) {
      _updateCurrentStep();
    } else {
      _currentStep = null;
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Load guide completed flag from local storage
  Future<void> _loadGuideStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _isGuideCompleted = prefs.getBool(_storageKey) ?? false;
    } catch (e) {
      log('Error loading guide status: $e');
    }
  }

  /// Save guide completed flag to local storage
  Future<void> _saveGuideStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, true);
    } catch (e) {
      log('Error saving guide status: $e');
    }
  }

  /// Update the current step to the next incomplete one
  void _updateCurrentStep() {
    _currentStep = null;
    for (final GuideShowCaseSteps step in GuideShowCaseSteps.values) {
      if (!_completedSteps.contains(step)) {
        _currentStep = step;
        break;
      }
    }
  }

  /// Whether a step should be shown
  bool shouldShowStep(GuideShowCaseSteps step) {
    if (_isGuideCompleted) return false;
    return _currentStep == step && !_completedSteps.contains(step);
  }

  /// Mark current step as completed (in-memory only)
  /// If last step, mark whole guide as completed in storage
  Future<void> completeStep() async {
    if (_isGuideCompleted) return;

    final GuideShowCaseSteps? step = _currentStep;
    if (step == null || _completedSteps.contains(step)) return;

    _completedSteps.add(step);

    // If the last step is reached, mark guide as fully completed
    if (step == GuideShowCaseSteps.values.last) {
      _isGuideCompleted = true;
      await _saveGuideStatus();
    }

    _updateCurrentStep();
    notifyListeners();
  }

  /// Skip the entire guide — mark it as completed immediately
  Future<void> skipGuide() async {
    _completedSteps
      ..clear()
      ..addAll(GuideShowCaseSteps.values);
    _isGuideCompleted = true;
    await _saveGuideStatus();
    _updateCurrentStep();
    notifyListeners();
  }
}

/// Extension to get user-friendly names for steps
extension GuideShowCaseStepsExtension on GuideShowCaseSteps {
  String get description {
    switch (this) {
      case GuideShowCaseSteps.uploadFloorPlan:
        return 'Upload your floor plan image';
      case GuideShowCaseSteps.showFloorPickCalibration:
        return 'Upload your floor plan image';
      case GuideShowCaseSteps.confirmFloorCalibrated:
        return 'Upload your floor plan image';
      case GuideShowCaseSteps.acousticMode:
        return 'Configure acoustic settings';
      case GuideShowCaseSteps.drawListeningArea:
        return 'Draw the listening area on your floor plan';
      case GuideShowCaseSteps.addZone:
        return 'Add acoustic zones';
      case GuideShowCaseSteps.addSpeakers:
        return 'Add speakers to your setup';
      case GuideShowCaseSteps.systemMode:
        return 'Choose your system mode';
      case GuideShowCaseSteps.systemModeTabs:
        return 'Configure system components';
      case GuideShowCaseSteps.selectListeningArea:
        return 'Select your listening area';
      case GuideShowCaseSteps.showListeningAreaSelectionArea:
        return 'Select your listening area';
      case GuideShowCaseSteps.confirmSelectListeningArea:
        return 'Select your listening area';
    }
  }
}
