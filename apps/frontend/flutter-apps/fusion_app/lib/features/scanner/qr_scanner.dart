import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/features/scanner/view_model/qr_scanner_view_model.dart';
import 'package:fusion_app/features/scanner/widgets/scan_instruction.dart';
import 'package:fusion_app/features/scanner/widgets/scanner_painter.dart';
import 'package:fusion_app/features/scanner/widgets/wifi_banner.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../authentication/presentation/login_page.dart';
import '../shared/presentation/widgets/common/empty_state.dart';

import 'package:vibration/vibration.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:light/light.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  MobileScannerController? controller;

  bool showErrorState = false;
  bool _isScanned = false;

  DateTime? _lastScanTime;

  StreamSubscription<Object?>? _subscription;

  ValueNotifier<bool> _isTorchOn = ValueNotifier(false);

  late AnimationController _animationController;
  late Animation<double> _animation;

 // final AudioPlayer _player = AudioPlayer();

  Light? _light;
  StreamSubscription<int>? _lightSub;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initScanner();
    _initAnimation();
    _startLightSensor();
  }

  void _initScanner() {
    controller = MobileScannerController(
      autoStart: false,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
    );

    unawaited(controller!.start());

    _subscription = controller!.barcodes.listen(_handleBarcode);

  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  void _startLightSensor() {
    _light = Light();

    _lightSub = _light!.lightSensorStream.listen((lux) {
      if (lux < 10 && !_isTorchOn.value) {
        controller?.toggleTorch();
        _isTorchOn.value = true;
      } else if (lux > 30 && _isTorchOn.value) {
        controller?.toggleTorch();
        _isTorchOn.value = false;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _subscription?.cancel();
    _lightSub?.cancel();

    _animationController.dispose();
    //_player.dispose();
    controller?.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _subscription = controller!.barcodes.listen(_handleBarcode);
        controller!.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _subscription?.cancel();
        controller!.stop();
        break;
      default:
        break;
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;

    if (value != null) {
      _handleScan(value);
    }
  }

  void _handleScan(String qrData) {
    final now = DateTime.now();

    /// 🔹 Debounce
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 2)) {
      return;
    }

    _lastScanTime = now;

    if (_isScanned) return;

    setState(() => _isScanned = true);

    controller?.stop();

    /// 🔹 Feedback
    Vibration.vibrate(duration: 100);
   // _player.play(AssetSource('sounds/beep.mp3'));

    /// 🔹 Call ViewModel
    context.read<QrScannerViewModel>().onQrScanned(qrData);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrScannerViewModel, QrScannerState>(
      listener: (context, state) {
        if (state is QrConnecting) {
          GlobalLoader().show(context);
        }

        if (state is QrConnected) {
          GlobalLoader().hide();

          if (loggedInUserId == 0) {
            Navigator.pushReplacementNamed(context, Routes.passcodePage);
          } else {
            Navigator.pushReplacementNamed(context, Routes.controlPalPage);
          }
        }

        if (state is QrError) {
          GlobalLoader().hide();

          setState(() => _isScanned = false);

          // TopBannerOverlay.show(
          //   context: context,
          //   message: state.message,
          //   type: BannerType.error,
          // );

          controller?.start();
        }
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Scan QR Code'),
        body: showErrorState ? _errorState() : _scannerView(),
      ),
    );
  }

  Widget _scannerView() {
    return Stack(
      children: [
        MobileScanner(controller: controller),

        AnimatedBuilder(
          animation: _animation,
          builder: (_, __) {
            return CustomPaint(
              size: Size.infinite,
              painter: ScannerOverlayPainter(
                context,
                scanProgress: _animation.value,
              ),
            );
          },
        ),

        Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: ScanInstruction(
            isFlashOn: _isTorchOn,
            onClickFlash: (value) {
              context.read<QrScannerViewModel>().onQrScanned("com.bosepro.fusion://connect?vip=192.168.1.100&controller_id=CONTROLLER632721600");
              _isTorchOn.value = value;
              controller?.toggleTorch();
            },
          ),
        ),

        const Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: WifiBanner(),
        ),
      ],
    );
  }

  Widget _errorState(){

      return CommonEmptyState(
        icon: Icons.signal_wifi_bad,
        title: "Can’t Connect to Network",
        subtitle:"Join the building’s Wi‑Fi network to continue",
        action: Container(
          width: 150,
          child: CustomButton(
            padding: EdgeInsets.zero,
            bottomPadding: 0,
            enabled: ValueNotifier(true),
            buttonText: 'Try Again',
            onPressed: () {
              setState(() {
                showErrorState=false;
              });

              // controller = MobileScannerController(
              //   autoStart: false,
              //   torchEnabled: false,
              //   detectionSpeed: DetectionSpeed.normal,
              //   detectionTimeoutMs: 250,
              //   returnImage: false,
              // );
              //
              //
              //
              // // Finally, start the scanner itself.
              // unawaited(controller!.start());
              // // Start listening to the barcode events.
              // _subscription = controller!.barcodes.listen(_handleBarcode);
              //
              //
              // _controller = AnimationController(
              //   vsync: this,
              //   duration: const Duration(seconds: 2),
              // )..repeat(reverse: false);
              //
              // _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
            },
          ),
        ),
      );
  }

}