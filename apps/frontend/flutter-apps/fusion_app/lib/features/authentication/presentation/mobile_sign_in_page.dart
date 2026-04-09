import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button/button.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';


class MobileSignInPage extends StatelessWidget {
  const MobileSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MobileSignInPageView();
  }
}

class _MobileSignInPageView extends StatelessWidget {
  const _MobileSignInPageView();

  @override
  Widget build(BuildContext context) {

    return  Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/bg-2.png",
            fit: BoxFit.cover,
          ),
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(26, 26, 24, 0.0),
                Color.fromRGBO(26, 26, 24, 0.79),
              ],
              stops: [0.0716, 1.0], // 7.16% → 0.0716
            ),
          ),
        ),
        Align(
          child: Container(
            child: Image.asset(
              "assets/Logo.png",
              width: 100,
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: CustomButton(
            enabled: ValueNotifier(true),
            buttonText: 'Lets Get Started',
            onPressed: () {

              Navigator.pushReplacementNamed(context, Routes.loginPage);
            },
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal:
            16.0,vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(child: SizedBox()),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Welcome to Fusion',
                            style: context.textTheme.b2Bold.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign into your Fusion account on the right and get started creating dynamic audio experiences',
                            style: context.textTheme.l1Regular.copyWith(
                              color: context.colorScheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


}


