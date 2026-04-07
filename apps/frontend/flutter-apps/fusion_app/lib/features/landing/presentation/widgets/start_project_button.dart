import 'package:flutter/material.dart';
import 'package:fusion_app/core/constants/color_constants.dart';

enum StartProjectButtonState {
  idle,
  loading,
  loaded,
}

class StartProjectButton extends StatelessWidget {
  const StartProjectButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  final StartProjectButtonState state;
  final VoidCallback onPressed;

  bool get _isLoading => state == StartProjectButtonState.loading;
  bool get _isLoaded => state == StartProjectButtonState.loaded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:  AppColors.successPrimary,
            disabledBackgroundColor: const Color(0xFF3FA374),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    Widget state = const Icon(
      Icons.arrow_forward,
      size: 18,
      color: AppColors.successPrimary,
    );
    if (_isLoading) {
      state = Container(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(7),
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.successPrimary,
        ),
      );
    }

    if (_isLoaded) {
      state =  const Icon(
        key: ValueKey('loaded'),
        Icons.check,
        color: AppColors.successPrimary,
        size: 22,
      );
    }

    return Row(
      key: const ValueKey('idle'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Start New Project',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: state,
        ),
      ],
    );
  }
}


