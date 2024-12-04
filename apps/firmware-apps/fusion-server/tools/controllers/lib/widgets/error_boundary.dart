import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  void Function(FlutterErrorDetails)? _originalOnError;

  @override
  void initState() {
    super.initState();
    _originalOnError = FlutterError.onError;
    FlutterError.onError = _handleError;
  }

  @override
  void dispose() {
    FlutterError.onError = _originalOnError;
    super.dispose();
  }

  void _handleError(FlutterErrorDetails details) {
    print('Caught error: ${details.exception}');
    _originalOnError?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
