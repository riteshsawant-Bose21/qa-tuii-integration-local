import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart'; // Assuming this contains your base widgets

enum UpdateStage { idle, copying, installing, success, failure }

class CompactFirmwareUpdateWidget extends StatefulWidget {
  const CompactFirmwareUpdateWidget({super.key});

  @override
  State<CompactFirmwareUpdateWidget> createState() => _CompactFirmwareUpdateWidgetState();
}

class _CompactFirmwareUpdateWidgetState extends State<CompactFirmwareUpdateWidget> {
  UpdateStage _stage = UpdateStage.idle;
  double _progress = 0.0;
  Timer? _simulationTimer;
  final Random _random = Random();

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _stage = UpdateStage.copying;
      _progress = 0.0;
    });
    _simulateProgress();
  }

  void _simulateProgress() {
    _simulationTimer?.cancel();
    // Update every 50ms to create a smooth loading effect
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 50), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress += 0.02; // Increment progress (50 steps = 2.5 seconds approx per stage)

        // STAGE TRANSITION LOGIC
        if (_progress >= 1.0) {
          if (_stage == UpdateStage.copying) {
            // Finished Copying -> Move to Installing
            _stage = UpdateStage.installing;
            _progress = 0.0;
          } else if (_stage == UpdateStage.installing) {
            // Finished Installing -> Determine Success or Failure
            timer.cancel();
            // 70% chance of success, 30% failure (randomized as requested)
            if (_random.nextDouble() > 0.3) {
              _stage = UpdateStage.success;
            } else {
              _stage = UpdateStage.failure;
            }
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Container styling to match the dark card look if needed,
    // or transparent to fit into an existing card.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_stage) {
      case UpdateStage.idle:
        return Center(
          child: FusionNeumorphicButton(
            text: "Check for Update",
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
              vertical: 2,
            ),
            borderRadius: 4,
            onTap: _startUpdate,
            textStyle: context.textTheme.labelMedium,
          ),
        );

      case UpdateStage.copying:
        return _buildProgressIndicator(
          label: "Copying files...",
          progress: _progress,
        );

      case UpdateStage.installing:
        return _buildProgressIndicator(
          label: "Installing...",
          progress: _progress,
        );

      case UpdateStage.failure:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              text: "Unable to Install",
              style: context.textTheme.labelMedium?.copyWith(
                color: const Color(0xFFFF7043), // Red/Orange error color
                fontStyle: FontStyle.italic,
              ),
            ),
            FusionNeumorphicButton(
              text: "Retry",
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              borderRadius: 4,
              // White button style as seen in the image
              textStyle: context.textTheme.labelSmall,
              onTap: _startUpdate, // Restart process
            ),
          ],
        );

      case UpdateStage.success:
        return Row(
          children: <Widget>[
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF66BB6A), // Success Green
              size: 20,
            ),
            const SizedBox(width: 12),
            FusionAppText(
              text: "Installation Complete",
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildProgressIndicator({required String label, required double progress}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Custom thinner progress bar to match image
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4, // Thin line
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF90CAF9)), // Light Blue
          ),
        ),
        const SizedBox(height: 8),
        FusionAppText(
          text: label,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.textSecondary,
            fontStyle: FontStyle.italic, // Matches the "Copying files..." style in image
          ),
        ),
      ],
    );
  }
}
