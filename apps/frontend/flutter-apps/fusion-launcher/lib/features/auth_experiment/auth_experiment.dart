import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'hero.dart';
import 'user.dart';

final Map<String, String> env = <String, String>{
  'AUTH0_DOMAIN': 'sujith-test.us.auth0.com',
  'AUTH0_CLIENT_ID': 'obYLFURabC69ar89V0HTQ36qKsDvwC0C',
  'AUTH0_CUSTOM_SCHEME': "fusion",
};

class AuthExperimentPage extends StatefulWidget {
  final Auth0? auth0;
  const AuthExperimentPage({this.auth0, super.key});

  @override
  State<AuthExperimentPage> createState() => _AuthExperimentPageState();
}

class _AuthExperimentPageState extends State<AuthExperimentPage> {
  UserProfile? _user;

  late Auth0 auth0;
  late Auth0Web auth0Web;

  @override
  void initState() {
    super.initState();
    auth0 = widget.auth0 ?? Auth0(env['AUTH0_DOMAIN']!, env['AUTH0_CLIENT_ID']!);
    auth0Web = Auth0Web(
      env['AUTH0_DOMAIN']!,
      env['AUTH0_CLIENT_ID']!,
    );

    if (kIsWeb) {
      auth0Web.onLoad().then(
        (final Credentials? credentials) => setState(() {
          _user = credentials?.user;
        }),
      );
    }
  }

  Future<void> login() async {
    try {
      if (kIsWeb) {
        return auth0Web.loginWithRedirect(redirectUrl: 'http://localhost:3000');
      }

      final Credentials credentials = await auth0
          .webAuthentication(scheme: env['AUTH0_CUSTOM_SCHEME'])
          // Use a Universal Link callback URL on iOS 17.4+ / macOS 14.4+
          // useHTTPS is ignored on Android
          .login(useHTTPS: false, redirectUrl: 'com.bosepro.fusion://sujith-test.us.auth0.com/macos/com.bosepro.fusion/callback');

      setState(() {
        _user = credentials.user;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        await auth0Web.logout(returnToUrl: 'http://localhost:3000');
      } else {
        await auth0
            .webAuthentication(scheme: env['AUTH0_CUSTOM_SCHEME'])
            // Use a Universal Link logout URL on iOS 17.4+ / macOS 14.4+
            // useHTTPS is ignored on Android
            .logout(useHTTPS: false, returnTo: 'com.bosepro.fusion://sujith-test.us.auth0.com/macos/com.bosepro.fusion/callback');
        setState(() {
          _user = null;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(
            top: padding,
            bottom: padding,
            left: padding / 2,
            right: padding / 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    _user != null ? Expanded(child: UserWidget(user: _user)) : const Expanded(child: HeroWidget()),
                  ],
                ),
              ),
              _user != null
                  ? ElevatedButton(
                    onPressed: logout,
                    child: const Text('Logout'),
                  )
                  : ElevatedButton(
                    onPressed: login,
                    child: const Text('Login'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
