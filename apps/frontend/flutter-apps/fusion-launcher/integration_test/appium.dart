import 'package:appium_flutter_server/appium_flutter_server.dart';
import 'package:desktop_auth0_flutter/desktop_auth0_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_launcher/core/config/app_config.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/main.dart';
import 'package:universal_platform/universal_platform.dart';

void main() {
  initializeTest(
    callback: (WidgetTester tester) async {
      // Any prerequisite steps or initialise any dependencies required by the app
      // and make sure to pump the app widget at last.
      WidgetsFlutterBinding.ensureInitialized();
    
    await AppConfig.initialize();

    await setupServiceLocator();
    if (UniversalPlatform.isWindows) {
      await initDesktopAuth0Flutter(
        const DesktopAuth0FlutterInitOptions(
          bundleName: 'com.bosepro.fusion',
          auth0Scheme: 'com.bosepro.fusion',
          categories: 'Office;Productivity',
          comment: 'Fusion Launcher',
          name: 'Fusion Launcher',
          iconAssetPath: 'assets/images/splash/splash_app_icon.png',
        ),
      );
    }
      await tester.pumpWidget(const MyApp());
    },
  );
}
