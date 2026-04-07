import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_app/features/scanner/view_model/qr_scanner_view_model.dart';
import 'package:fusion_app/features/zones/view_model/controlpal_zone_view_model.dart';
import 'package:fusion_lib/fusion_theme/fusion_theme_notifier.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:nested/nested.dart' show SingleChildWidget;
import 'package:responsive_framework/responsive_framework.dart';

import 'core/config/app_config.dart';
import 'core/router/navigation_observer.dart';
import 'core/router/routes.dart';
import 'core/service_locator.dart';
import 'features/authentication/viewmodel/auth_view_model.dart';
import 'features/authentication/viewmodel/session_view_model.dart';
import 'features/landing/viewmodel/project_view_model.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      //DeviceOrientation.landscapeLeft,
    ]);
    final uri = Uri(
      scheme: 'com.bosepro.fusion',
      host: 'connect',
      queryParameters: {
        'vip': '192.168.1.110',
        'controller_id': 'CTRL1762958340064766236',
      },
    );

    final s = uri.toString();

    final qrString = jsonEncode(s);
    print("qrString");
    print(qrString);
   await AppConfig.initialize();

    await setupServiceLocator();
    FusionUtils();
    FusionThemeController.setThemeMode(ThemeMode.dark);
    runApp(const MyApp());

    //TODO: Only for web automation build
    //This needs to be conditionally switched on based on some commandline param.
    //Else, this would create the semantics tree everytime misusing computation power.
    SemanticsBinding.instance.ensureSemantics();

    //_setupMacOSDeepLinkListener();
  }, reportCrash);
}

Future<void> reportCrash(Object exception, StackTrace stack) async {
  // try {
  //   FusionLogger.log(tag: LogTag.exceptions, message: "Exception: ${exception.toString()} \n, StackTrace: ${stack.toString()} ");
  //   // FirebaseCrashlytics.instance.recordError(exception, stack);
  // } catch (ex) {
  //   debugPrint("Unable to report crash: $ex");
  // }
}

void _setupMacOSDeepLinkListener() {
  if (kIsWeb) {
    return;
  }
  // Use MethodChannel to receive the URL from native code
  const MethodChannel channel = MethodChannel('custom_url_scheme_channel');
  channel.setMethodCallHandler((MethodCall call) async {
    debugPrint(
      'Received method call: ${call.method} with arguments: ${call.arguments}',
    );
    if (call.method == 'onCustomUrlScheme') {
      final String url = call.arguments as String;
      // Handle the URL here
      debugPrint('Received deep link: $url');
      // You can navigate or update state as needed
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<SessionViewModel>.value(
          value: serviceLocator<SessionViewModel>(),
        ),
        //
        BlocProvider<AuthViewModel>.value(
          value: serviceLocator<AuthViewModel>()..initialize(),
          // lazy: false,
        ),
        BlocProvider<QrScannerViewModel>.value(
          value: serviceLocator<QrScannerViewModel>(),
          // lazy: false,
        ),
        BlocProvider<ProjectViewModel>(
          create: (BuildContext context) => serviceLocator<ProjectViewModel>(),
        ),
        BlocProvider<ControlPalZonesViewModel>(
          create: (BuildContext context) => serviceLocator<ControlPalZonesViewModel>(),
        ),
        // BlocProvider<ProductQueryCubit>(
        //   create: (BuildContext context) => serviceLocator<ProductQueryCubit>(),
        // ),
        BlocProvider<GuideShowCaseController>(
          create: (BuildContext context) => serviceLocator<GuideShowCaseController>(),
        ),
      ],
      child: FusionThemeBuilder(
        builder: (BuildContext context, ThemeMode mode) {
          return BlocConsumer<SessionViewModel, SessionViewModelState>(
            // Listener: Handle one-off events like errors (optional)
            listener: (BuildContext context, SessionViewModelState state) {
              // if (state is SessionExpired) {
              //   // USAGE: Use the Global Key to navigate
              //   // pushNamedAndRemoveUntil ensures the user can't go 'back' to the protected page
              //   globalNavigatorKey.currentState?.pushNamedAndRemoveUntil(
              //     Routes.mobileSignInPage,
              //         (Route<dynamic> route) => false, // Remove all previous routes
              //   );
              // }
            },
            builder: (BuildContext context, SessionViewModelState state) {
              return ValueListenableBuilder<ThemeMode>(
                  valueListenable: FusionThemeController.themeModeNotifier,
                  builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
                  return MaterialApp(
                    title: 'Fusion Mobile',
                    debugShowCheckedModeBanner: false,
                    theme: FusionAppTheme.lightTheme,
                    darkTheme: FusionAppTheme.darkTheme,
                    themeMode: themeMode,
                    builder: (context, child) => ResponsiveBreakpoints.builder(
                      child: Builder(
                        builder: (context) {
                          return ResponsiveScaledBox(
                              width: ResponsiveValue<double>(
                                  defaultValue: 390,
                                  context,
                                  conditionalValues: [
                                    Condition.equals(name: MOBILE, value: 390),
                                  ]).value,
                              child: child!
                          );
                        }
                      ),
                      breakpoints: [
                        const Breakpoint(start: 0, end: 800, name: MOBILE),
                      ],
                    ),
                    // home:
                    // (state is SessionValid)
                    //     ?    LandingScreen()
                    //     :  LandingScreen(),

                    navigatorKey: globalNavigatorKey,
                    navigatorObservers: <NavigatorObserver>[
                      AppNavigatorObserver(),
                    ],
                    onGenerateRoute: (RouteSettings settings) => Routes.onGenerateRoute(settings),
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}
