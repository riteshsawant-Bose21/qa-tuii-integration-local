import 'package:flutter/material.dart';
import 'package:fusion_launcher/core/widgets/animated_action_widget.dart';
import 'package:fusion_launcher/core/widgets/animated_widget_changer.dart';
import 'package:fusion_launcher/core/widgets/gradient_action_button.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/widgets/launcher_background.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

import '../../../../core/router/routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const List<String> _texts = <String>[
    'Experience Audio Systems',
    'Configure Audio Systems',
    'Design Audio Systems',
    'Program Audio Systems',
  ];

  static const List<List<MaterialColor>> _gradients = <List<MaterialColor>>[
    <MaterialColor>[Colors.purple, Colors.pink],
    <MaterialColor>[Colors.green, Colors.teal],
    <MaterialColor>[Colors.pink, Colors.red],
    <MaterialColor>[Colors.orange, Colors.amber],
    <MaterialColor>[Colors.blue, Colors.indigo],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: LauncherBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      height: 20,
                    ),

                    /// Fusion app Icon
                    SizedBox(
                      height: 160,
                      child: Image.asset("assets/images/splash/splash_app_icon.png"),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome to Fusion Suite',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w100,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Powered by',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w100,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      width: 140,
                      child: Image.asset(
                        "assets/images/bose_pro_logo_new.png",
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(
                      height: 120,
                    ),
                    SizedBox(
                      height: 120,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Redefining how you',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.labelSmall?.color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedWidgetChanger(
                            textWidgetsList: List<GradientText>.generate(
                              _texts.length,
                              (int i) {
                                return GradientText(
                                  _texts[i],
                                  colors: _gradients[i],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                            duration: 3000,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GradientActionButton(
              label: 'Get Started',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  Routes.launcherSignInPage,
                );
              },
              trailing: const AnimatedActionWidget(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
