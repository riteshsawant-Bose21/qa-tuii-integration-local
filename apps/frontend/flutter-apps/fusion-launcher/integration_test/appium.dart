import 'package:appium_flutter_server/appium_flutter_server.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/main.dart';

void main() {
  initializeTest(
    callback: (WidgetTester tester) async {
       // Any prerequisite steps or intialise any dependencies required by the app
       // and make sure to pump the app widget at last.
      WidgetsFlutterBinding.ensureInitialized();
      await setupServiceLocator();
      await tester.pumpWidget(const MyApp());
    },
  );
}