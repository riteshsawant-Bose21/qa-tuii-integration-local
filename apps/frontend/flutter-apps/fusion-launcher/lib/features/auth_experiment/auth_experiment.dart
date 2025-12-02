// import 'package:auth0_flutter/auth0_flutter.dart';
// import 'package:auth0_flutter/auth0_flutter_web.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import 'constants.dart';
// import 'hero.dart';
// import 'user.dart';



// class AuthExperimentPage extends StatefulWidget {
//   final Auth0? auth0;
//   const AuthExperimentPage({this.auth0, super.key});

//   @override
//   State<AuthExperimentPage> createState() => _AuthExperimentPageState();
// }

// class _AuthExperimentPageState extends State<AuthExperimentPage> {
  

//   @override
//   Widget build(final BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Padding(
//           padding: const EdgeInsets.only(
//             top: padding,
//             bottom: padding,
//             left: padding / 2,
//             right: padding / 2,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: <Widget>[
//               Expanded(
//                 child: Row(
//                   children: <Widget>[
//                     _user != null ? Expanded(child: UserWidget(user: _user)) : const Expanded(child: HeroWidget()),
//                   ],
//                 ),
//               ),
//               _user != null
//                   ? ElevatedButton(
//                     onPressed: logout,
//                     child: const Text('Logout'),
//                   )
//                   : ElevatedButton(
//                     onPressed: login,
//                     child: const Text('Login'),
//                   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
