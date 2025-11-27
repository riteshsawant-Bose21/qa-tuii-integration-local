import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/router/routes.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/user_account_setup/presentation/bloc/auth_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/fusion_utils.dart';
import '../widgets/account_creation_success_popup.dart';

class LauncherSignInPage extends StatefulWidget {
  const LauncherSignInPage({super.key});

  @override
  State<LauncherSignInPage> createState() => _LauncherSignInPageState();
}

class _LauncherSignInPageState extends State<LauncherSignInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  ValueNotifier<bool> obscuredNotifier = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    obscuredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Make it scalable for larger screens
    final double headlineFontSize = MediaQuery.of(context).size.width * 0.07;
    final double subHeadingFontSize = MediaQuery.of(context).size.width * 0.02;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (BuildContext context, AuthState state) {
          if (state is AuthInProgress) {
            FusionUiUtils.showLoader(context);
          } else {
            FusionUiUtils.hideLoader(context);
          }
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthSuccess) {
            if (!context.mounted) return;
            showSuccessPopup(
              context,
              () async {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.launcherHomePage,
                  (Route<dynamic> route) => false,
                );
              },
              durationInMils: 2500,
            );
          }
        },
        builder: (BuildContext context, AuthState state) {
          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Form(
              key: _formKey,
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
                              'Welcome to\nFusion',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: headlineFontSize > 120 ? 120 : headlineFontSize,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Sign into your Fusion account on the right and\nget started creating dynamic audio experiences',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: FusionDarkColorPallette.medium50,
                                fontSize: subHeadingFontSize > 16 ? 16 : subHeadingFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 500,
                          ),
                          decoration: BoxDecoration(
                            color: FusionDarkColorPallette.surface.withValues(alpha: 0.1),
                            boxShadow: <BoxShadow>[
                              const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-2, -2)),
                              const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(2, 2)),
                              BoxShadow(color: FusionDarkColorPallette.surface.withValues(alpha: 0.9), blurRadius: 3),
                            ],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            spacing: 10,
                            children: <Widget>[
                              Row(
                                spacing: 10,
                                children: <Widget>[
                                  Expanded(
                                    child: NeumorphicDarkTextField(
                                      hintText: 'Email',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (String? value) {
                                        /// Allow local admin login for testing purposes
                                        if (value == "admin") return null;
                                        if (value == null || value.isEmpty) return "Enter email";
                                        final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                        if (!emailRegex.hasMatch(value)) return "Enter a valid email address";
                                        return null;
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: obscuredNotifier,
                                      builder: (BuildContext context, bool isObscured, Widget? child) {
                                        return NeumorphicDarkTextField(
                                          hintText: 'Password',
                                          controller: _passwordController,
                                          suffix: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: () => obscuredNotifier.value = !obscuredNotifier.value,
                                              child: Icon(
                                                isObscured ? LucideIcons.eyeClosed : LucideIcons.eye,
                                                size: 15,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          isObscured: isObscured,
                                          validator: (String? value) {
                                            /// Allow local admin login for testing purposes
                                            if (value == "admin") return null;

                                            if (value == null || value.isEmpty) return "Enter password or click on the eye icon to show password";
                                            if (value.trim().length < 8) return "Password must be at least 8 digits";
                                            return null;
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              NeumorphicDarkButton(
                                onTap: () {
                                  if (_formKey.currentState!.validate()) {
                                    final SignInRequested newState = SignInRequested(_emailController.text, _passwordController.text);
                                    serviceLocator<AuthBloc>().add(newState);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Row(
                                    spacing: 10,
                                    children: <Widget>[
                                      Expanded(
                                        child: FusionAppText(
                                          text: 'Log in',
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      Container(
                                        height: 28,
                                        width: 47,
                                        decoration: BoxDecoration(
                                          color: FusionDarkColorPallette.green20,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          LucideIcons.arrowRight,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NeumorphicDarkTextField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final String? hintText;
  final double borderRadius;
  final Widget? prefix;
  final Widget? suffix;
  final bool isObscured;

  const NeumorphicDarkTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.borderRadius = 12,
    this.prefix,
    this.suffix,
    this.isObscured = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
            const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
            const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            validator: validator,
            style: Theme.of(context).textTheme.labelLarge,
            obscureText: isObscured,
            decoration: InputDecoration(
              prefixIcon: prefix,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffix,
              filled: true,
              isDense: true,
              fillColor: const Color(0xFF282826),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: hintText,
              hoverColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicDarkButton extends StatefulWidget {
  final String? text;
  final Widget? child;

  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double borderRadius;
  const NeumorphicDarkButton({
    super.key,
    this.text,
    this.borderRadius = 12,
    this.child,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<NeumorphicDarkButton> createState() => _NeumorphicDarkButtonState();
}

class _NeumorphicDarkButtonState extends State<NeumorphicDarkButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    assert(widget.text != null || widget.child != null);

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapCancel: () => setState(() => isPressed = false),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height ?? 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            if (isPressed) ...<BoxShadow>[
              const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
              const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
              const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
            ] else ...<BoxShadow>[
              const BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(0.5, 1)),
              const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-0.5, -1)),
            ],
          ],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF232523),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Center(
              child: widget.child ?? FusionAppText(text: widget.text!),
            ),
          ),
        ),
      ),
    );
  }
}

// class LauncherSignInPage extends StatefulWidget {
//   const LauncherSignInPage({super.key});

//   @override
//   State<LauncherSignInPage> createState() => _LauncherSignInPageState();
// }

// class _LauncherSignInPageState extends State<LauncherSignInPage> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool obscured = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _login() async {
//     if (_formKey.currentState!.validate()) {
//       serviceLocator<AuthBloc>().add(SignInRequested(_emailController.text, _passwordController.text));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<AuthBloc, AuthState>(
//       listener: (BuildContext context, AuthState state) {
//         if (state is AuthInProgress) {
//           log("AuthLoading");
//           FusionUiUtils.showLoader(context);
//         } else {
//           FusionUiUtils.hideLoader(context);
//         }
//         if (state is AuthFailure) {
//           log("AuthFailure: ${state.message}");
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message)),
//           );
//         } else if (state is AuthSuccess) {
//           if (!context.mounted) return;
//           showSuccessPopup(
//             context,
//             () async {
//               Navigator.pushNamedAndRemoveUntil(
//                 context,
//                 Routes.launcherHomePage,
//                 (Route<dynamic> route) => false,
//               );
//             },
//             durationInMils: 2500,
//           );
//         }
//       },
//       builder: (BuildContext context, AuthState state) {
//         return Scaffold(
//           extendBody: true,
//           extendBodyBehindAppBar: true,
//           appBar: AppBar(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             surfaceTintColor: Colors.transparent,
//           ),
//           body: LauncherBackground(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24),
//                 child: SafeArea(
//                   top: false,
//                   child: Align(
//                     alignment: Alignment.center,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(32),
//                       clipBehavior: Clip.hardEdge,
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(
//                           sigmaX: 8,
//                           sigmaY: 8,
//                         ),
//                         child: Form(
//                           key: _formKey,
//                           child: Container(
//                             constraints: const BoxConstraints(maxWidth: 720),
//                             color:
//                                 Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.025) : Colors.black.withValues(alpha: 0.025),
//                             padding: const EdgeInsets.all(24.0),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               mainAxisSize: MainAxisSize.max,
//                               children: <Widget>[
//                                 const SizedBox(height: 12.0),
//                                 Image.asset(
//                                   "assets/images/bose_pro_logo_new.png",
//                                   height: 72,
//                                   fit: BoxFit.fitHeight,
//                                   color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
//                                 ),
//                                 const SizedBox(height: 12.0),
//                                 AppTextView(
//                                   text: "Sign in to your Bose Professional account",
//                                   style: Theme.of(context).textTheme.titleSmall,
//                                 ),
//                                 const SizedBox(height: 48.0),
//                                 AppTextField(
//                                   controller: _emailController,
//                                   title: "Email address",
//                                   onValueChange: (String value) {},
//                                   keyboardType: TextInputType.emailAddress,
//                                   validator: (String? value) {
//                                     /// Allow local admin login for testing purposes
//                                     if (value == "admin") return null;

//                                     if (value == null || value.isEmpty) {
//                                       return "Enter email";
//                                     }
//                                     final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//                                     if (!emailRegex.hasMatch(value)) {
//                                       return "Enter a valid email address";
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                                 const SizedBox(height: 12),
//                                 AppTextField(
//                                   controller: _passwordController,
//                                   title: "Password",
//                                   suffixIcon: GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         obscured = !obscured;
//                                       });
//                                     },
//                                     child: Icon(
//                                       obscured ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
//                                       size: 15,
//                                       color: Theme.of(context).colorScheme.primaryColor,
//                                     ),
//                                   ),
//                                   obscureText: obscured,
//                                   validator: (String? value) {
//                                     /// Allow local admin login for testing purposes
//                                     if (value == "admin") return null;

//                                     if (value == null || value.isEmpty) {
//                                       return "Enter password";
//                                     }
//                                     if (value.trim().length < 8) {
//                                       return "Password must be at least 8 digits";
//                                     }
//                                     return null;
//                                   },
//                                   onValueChange: (String value) {},
//                                 ),
//                                 const SizedBox(height: 36.0),
//                                 GradientActionButton(
//                                   label: 'Sign In',
//                                   height: 50,
//                                   width: 200,
//                                   onTap: _login,
//                                   trailing: const AnimatedActionWidget(
//                                     offset: 0.0,
//                                     child: Icon(
//                                       Icons.login,
//                                       color: Colors.white,
//                                       size: 18,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 36),
//                                 const AppTextView(
//                                   text: "Forgot Password?",
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: <Widget>[
//                                     const Spacer(),
//                                     const AppTextView(
//                                       text: "Don't have an account? ",
//                                     ),
//                                     TextButton(
//                                       onPressed: () {
//                                         Navigator.pushNamed(
//                                           context,
//                                           Routes.launcherSignUpPage,
//                                         );
//                                       },
//                                       child: const Text(
//                                         "Sign Up",
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           color: Colors.blue,
//                                         ),
//                                       ),
//                                     ),
//                                     //seetings icon at the right corner
//                                     const Spacer(),
//                                     IconButton(
//                                       icon: const Icon(
//                                         Icons.settings,
//                                         size: 20,
//                                       ),
//                                       tooltip: "Settings",
//                                       onPressed: () {
//                                         _showSettingsDialog(context);
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

// //Dialog with 3 text fields for 3 different  Ip address endpoint setting
// void _showSettingsDialog(BuildContext context) {
//   // Controllers for the text fields
//   final TextEditingController droAddressController = TextEditingController(text: serviceLocator<FusionPreferences>().droServerUrl);
//   final TextEditingController backendUrlController = TextEditingController(text: serviceLocator<FusionPreferences>().fusionCloudBackendUrl);
//   final TextEditingController cloudWebUrlController = TextEditingController(text: serviceLocator<FusionPreferences>().cloudWebUrl);

//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         backgroundColor: AppColors.backgroundSoft,
//         title: const Center(
//           child: Column(
//             children: <Widget>[
//               Text(
//                 "Settings",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 8),
//               Divider(
//                 color: Colors.grey,
//                 height: 1,
//               ),
//             ],
//           ),
//         ),
//         content: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.8,
//             maxHeight: MediaQuery.of(context).size.height * 0.7,
//             minHeight: 300,
//             minWidth: 300,
//           ),
//           color: AppColors.backgroundSoft,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 // DRO IP Section
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       Text(
//                         'DRO IP',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: droAddressController,
//                         decoration: const InputDecoration(
//                           hintText: 'Enter DRO IP address',
//                           isDense: true,
//                           border: OutlineInputBorder(),
//                           contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                         ),
//                         style: const TextStyle(fontSize: 12),
//                       ),
//                       const SizedBox(height: 8),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 28,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             // validate ip address and update project
//                             final String ip = droAddressController.text.trim();
//                             serviceLocator<FusionPreferences>().setDroServerUrl(ip);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text('DRO IP updated to $ip'),
//                                 backgroundColor: Colors.green.shade600,
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.grey.shade800,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                             elevation: 0,
//                           ),
//                           child: const Text('Update', style: TextStyle(fontSize: 11)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Backend Address Section
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       Text(
//                         'Backend Address',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: backendUrlController,
//                         readOnly: false,
//                         decoration: InputDecoration(
//                           hintText: '192.168.1.100',
//                           isDense: true,
//                           border: const OutlineInputBorder(),
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                           disabledBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                         style: const TextStyle(fontSize: 12),
//                         enabled: true,
//                       ),
//                       const SizedBox(height: 8),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 28,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             serviceLocator<FusionPreferences>().setFusionCloudBackendUrl(backendUrlController.text);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.grey.shade800,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                             elevation: 0,
//                           ),
//                           child: const Text('Configure', style: TextStyle(fontSize: 11)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Backend Address Section
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(6),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       Text(
//                         'Cloud web url',
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade700,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         controller: cloudWebUrlController,
//                         readOnly: false,
//                         decoration: InputDecoration(
//                           hintText: '192.168.1.100',
//                           isDense: true,
//                           border: const OutlineInputBorder(),
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                           disabledBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                         style: const TextStyle(fontSize: 12),
//                         enabled: true,
//                       ),
//                       const SizedBox(height: 8),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 28,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             serviceLocator<FusionPreferences>().setCloudWebUrl(cloudWebUrlController.text);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.grey.shade800,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//                             elevation: 0,
//                           ),
//                           child: const Text('Configure', style: TextStyle(fontSize: 11)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         actionsAlignment: MainAxisAlignment.center,
//         actions: <Widget>[
//           Center(
//             child: TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text(
//                 "Close",
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Theme.of(context).colorScheme.primaryColor,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }

// }
