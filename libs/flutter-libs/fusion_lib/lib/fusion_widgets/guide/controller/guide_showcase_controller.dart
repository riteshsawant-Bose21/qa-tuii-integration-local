import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fusion_lib.dart';

class GuideShowCaseControllerTexts {
  static const String storageKey = 'is_guide_showcase_step_completed';

  static const String errorLoadingGuideStatusPrefix = 'Error loading guide status:';
  static const String errorSavingGuideStatusPrefix = 'Error saving guide status:';

  static const String uploadFloorPlan = 'A floor plan provides the spatial layout for your audio system. Tap here to upload a floor plan image';
  static const String configureAcousticSettings =
      'Acoustics mode lets you design your audio layout by defining listening areas and speaker placement. Switch to this mode to configure your acoustic settings';
  static const String drawListeningArea =
      'Listening areas define where people will be positioned to hear audio. Draw listening areas on the canvas using this drawing tool';
  static const String addAcousticZones = 'Acoustic zones group listening areas with similar audio requirements. Add acoustic zones to organize your layout';
  static const String selectSpeakersTool = 'Speakers provide audio coverage to your listening areas. Tap here to add speakers to the layout';
  static const String addSpeakers = 'Pick a speaker model and place it on the floor plan';
  static const String selectListeningArea =
      'Each listening area can be configured individually for optimal audio experience. Select a listening area to configure it';

  static const String myProjects = 'Tap here to create a new project';
  static const String showFloorPickCalibration =
      'Calibration ensures accurate measurements and distances in your floor plan. Draw two reference points to calibrate your floor plan';
  static const String confirmFloorCalibrated = 'Confirm your floor plan calibration to proceed';
  static const String acousticMode = 'Acoustics mode focuses on audio design and speaker placement';
  static const String systemMode = 'Switch to System mode to configure other hardware components like sources, endpoints, and more';
  static const String systemModeTabs = 'Tap here to add a source';
  static const String addZone = 'A zone is where the same audio is played. Tap here to add a new zone';
  static const String showListeningAreaSelectionArea = 'Zones need listening areas to define where audio will be heard. Choose listening areas for this zone';
  static const String confirmSelectListeningArea = 'Confirm your selected listening areas';
}

enum GuideShowCaseSteps {
  myProjects,
  uploadFloorPlan,
  showFloorPickCalibration,
  confirmFloorCalibrated,
  acousticMode,
  drawListeningArea,
  selectSpeakersTool,
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
      case GuideShowCaseSteps.selectSpeakersTool:
        return GuideShowCaseControllerTexts.selectSpeakersTool;
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
