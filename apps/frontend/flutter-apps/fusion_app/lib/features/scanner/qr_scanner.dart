import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/core/utils/qr_data_parser.dart';
import 'package:fusion_app/features/scanner/widgets/scan_instruction.dart';
import 'package:fusion_app/features/scanner/widgets/scanner_painter.dart';
import 'package:fusion_app/features/scanner/widgets/wifi_banner.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../authentication/presentation/login_page.dart';
import '../shared/presentation/widgets/common/empty_state.dart';
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>  with WidgetsBindingObserver,SingleTickerProviderStateMixin{
   MobileScannerController? controller;
  bool showErrorState = true;
  StreamSubscription<Object?>? _subscription;
  bool _isScanned = false;
  ValueNotifier<bool> _isTorchOn = ValueNotifier(false);
   late AnimationController _controller;
   late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

  }

  @override
  Future<void> dispose() async {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    _controller.dispose();
    super.dispose();
    // Finally, dispose of the controller.
    await controller!.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    // if (!controller.value.hasCameraPermission) {
    //   return;
    // }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
      // Restart the scanner when the app is resumed.
      // Don't forget to resume listening to the barcode events.
        _subscription = controller!.barcodes.listen(_handleBarcode);



          _isTorchOn.value = controller!.torchEnabled;

        unawaited(controller!.start());
      case AppLifecycleState.inactive:
      // Stop the scanner when the app is paused.
      // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller!.stop());
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonAppBar(title: 'Scan QR Code'),
      body:  showErrorState ? getErrorState() :scannerView(),
    );
  }

  void _handleScan(String qrData) {
    if (_isScanned) return;

    setState(() {
      _isScanned = true;
    });

    // Stop camera
    controller!.stop();

    GlobalLoader().hide();
    GlobalLoader().show(context);

      Future.delayed(Duration(milliseconds: 600),(){
        GlobalLoader().hide();
        if(loggedInUserId==0){
          Navigator.pushReplacementNamed(context, Routes.passcodePage);
        }else{
          Navigator.pushReplacementNamed(context, Routes.controlPalPage);
        }


      });


    final details = QRConnectionParser.parse(qrData);
  }

  Widget scannerView(){
    return Stack(
      children: [

        /// Camera
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (_isScanned) return;

            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleScan(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        /// Scanner Overlay
        GestureDetector(
          onTap: (){
            if(loggedInUserId==0){
              Navigator.pushReplacementNamed(context, Routes.passcodePage);
            }else{
              Navigator.pushReplacementNamed(context, Routes.controlPalPage);
            }


          },
          child: AnimatedBuilder(
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
          )
        ),

        /// Instructions
         Positioned(
          bottom: 160,
          left: 0,
          right: 0,
          child: ScanInstruction(onClickFlash: (bool value){
            _isTorchOn.value = value;
              controller!.toggleTorch();
          }, isFlashOn: _isTorchOn,),
        ),

        /// Wifi banner
        const Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: WifiBanner(),
        ),
      ],
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    final Barcode? barcode = capture.barcodes.firstOrNull;

    final String? value = barcode?.rawValue;

    if (value == null) return;

    debugPrint("QR Code: $value");

    /// Stop scanning to prevent duplicates
    controller!.stop();

    /// Example navigation
    // Navigator.push(...)
  }

  Widget getErrorState(){

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

              controller = MobileScannerController(
                autoStart: false,
                torchEnabled: false,
                detectionSpeed: DetectionSpeed.normal,
                detectionTimeoutMs: 250,
                returnImage: false,
              );



              // Finally, start the scanner itself.
              unawaited(controller!.start());
              // Start listening to the barcode events.
              _subscription = controller!.barcodes.listen(_handleBarcode);


              _controller = AnimationController(
                vsync: this,
                duration: const Duration(seconds: 2),
              )..repeat(reverse: false);

              _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
            },
          ),
        ),
      );
  }

}