import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideShowCaseControllerTexts {
  static const String storageKey = 'is_guide_showcase_step_completed';

  static const String errorLoadingGuideStatusPrefix = 'Error loading guide status:';
  static const String errorSavingGuideStatusPrefix = 'Error saving guide status:';

  static const String uploadFloorPlan = 'Upload a floor plan image';
  static const String configureAcousticSettings = 'Configure acoustic settings';
  static const String drawListeningArea = 'Draw listening areas on the canvas';
  static const String addAcousticZones = 'Add acoustic zones';
  static const String addSpeakers = 'Add speakers to the layout';
  static const String chooseSystemMode = 'Choose your system mode'; // legacy
  static const String configureSystemComponents = 'Configure system components in tabs';
  static const String selectListeningArea = 'Select a listening area';

  static const String myProjects = 'Create a new project';
  static const String showFloorPickCalibration = 'Pick a reference distance for calibration';
  static const String confirmFloorCalibrated = 'Confirm floor plan calibration';
  static const String acousticMode = 'Switch to Acoustics mode';
  static const String systemMode = 'Switch to System mode';
  static const String systemModeTabs = 'Review and configure system components';
  static const String addZone = 'In Acoustics mode, define listening areas, place speakers, and visualize sound coverage.';
  static const String showListeningAreaSelectionArea = 'Choose listening areas for this zone';
  static const String confirmSelectListeningArea = 'Confirm selected listening areas';
}

enum GuideShowCaseSteps {
  myProjects,
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
  final Set<GuideShowCaseSteps> _completedSteps = <GuideShowCaseSteps>{};
  GuideShowCaseSteps? _currentStep;
  bool _isInitialized = false;
  bool _isGuideCompleted = false;

  late final BuildContext _context;

  GuideShowCaseController(BuildContext context) {
    _context = context;
    _initialize();
  }

  // Getters
  GuideShowCaseSteps? get currentStep => _currentStep;
  bool get isInitialized => _isInitialized;
  bool get isGuideCompleted => _isGuideCompleted;
  Set<GuideShowCaseSteps> get completedSteps => Set<GuideShowCaseSteps>.unmodifiable(_completedSteps);

  Future<void> guideNeeded() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clear any previous saved state
    await prefs.remove(GuideShowCaseControllerTexts.storageKey);

    // Reset all internal states
    _completedSteps.clear();
    _isGuideCompleted = false;
    _currentStep = null;

    // Recalculate the first step
    _updateCurrentStep();

    // Notify UI about reset
    notifyListeners();
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
      _isGuideCompleted = prefs.getBool(GuideShowCaseControllerTexts.storageKey) ?? false;
    } catch (e) {
      log('${GuideShowCaseControllerTexts.errorLoadingGuideStatusPrefix} $e');
    }
  }

  /// Save guide completed flag to local storage
  Future<void> _saveGuideStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(GuideShowCaseControllerTexts.storageKey, true);
    } catch (e) {
      log('${GuideShowCaseControllerTexts.errorSavingGuideStatusPrefix} $e');
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

      // ignore: use_build_context_synchronously
      GuideShowcaseWrapper.showGuideCompletedDialog(_context);
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
      case GuideShowCaseSteps.myProjects:
        return GuideShowCaseControllerTexts.myProjects;
      case GuideShowCaseSteps.uploadFloorPlan:
        return GuideShowCaseControllerTexts.uploadFloorPlan;
      case GuideShowCaseSteps.showFloorPickCalibration:
        return GuideShowCaseControllerTexts.showFloorPickCalibration;
      case GuideShowCaseSteps.confirmFloorCalibrated:
        return GuideShowCaseControllerTexts.confirmFloorCalibrated;
      case GuideShowCaseSteps.acousticMode:
        return GuideShowCaseControllerTexts.acousticMode;
      case GuideShowCaseSteps.drawListeningArea:
        return GuideShowCaseControllerTexts.drawListeningArea;
      case GuideShowCaseSteps.addSpeakers:
        return GuideShowCaseControllerTexts.addSpeakers;
      case GuideShowCaseSteps.systemMode:
        return GuideShowCaseControllerTexts.systemMode;
      case GuideShowCaseSteps.systemModeTabs:
        return GuideShowCaseControllerTexts.systemModeTabs;
      case GuideShowCaseSteps.addZone:
        return GuideShowCaseControllerTexts.addZone;
      case GuideShowCaseSteps.selectListeningArea:
        return GuideShowCaseControllerTexts.selectListeningArea;
      case GuideShowCaseSteps.showListeningAreaSelectionArea:
        return GuideShowCaseControllerTexts.showListeningAreaSelectionArea;
      case GuideShowCaseSteps.confirmSelectListeningArea:
        return GuideShowCaseControllerTexts.confirmSelectListeningArea;
    }
  }
}
