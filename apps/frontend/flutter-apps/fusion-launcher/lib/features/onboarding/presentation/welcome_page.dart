// class WelcomePage extends StatelessWidget {
//   const WelcomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Make it scalable for larger screens
//     final double headlineFontSize = MediaQuery.of(context).size.width * 0.07;
//     final double subHeadingFontSize = MediaQuery.of(context).size.width * 0.02;

//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(40.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             const Expanded(child: SizedBox()),
//             Row(
//               children: <Widget>[
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: <Widget>[
//                       Text(
//                         'Welcome to\nFusion',
//                         style: Theme.of(context).textTheme.displayLarge?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           fontSize: headlineFontSize > 120 ? 120 : headlineFontSize,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       Text(
//                         'Sign into your Fusion account on the right and\nget started creating dynamic audio experiences',
//                         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                           color: FusionDarkColorPallette.medium50,
//                           fontSize: subHeadingFontSize > 16 ? 16 : subHeadingFontSize,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(24),
//                   child: Container(
//                     constraints: const BoxConstraints(
//                       maxWidth: 500,
//                     ),
//                     decoration: BoxDecoration(
//                       color: FusionDarkColorPallette.surface.withValues(alpha: 0.1),
//                       boxShadow: <BoxShadow>[
//                         const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-2, -2)),
//                         const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(2, 2)),
//                         BoxShadow(color: FusionDarkColorPallette.surface.withValues(alpha: 0.9), blurRadius: 3),
//                       ],
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       spacing: 10,
//                       children: <Widget>[
//                         const Row(
//                           spacing: 10,
//                           children: <Widget>[
//                             Expanded(
//                               child: NeumorphicDarkTextField(
//                                 hintText: 'Email',
//                               ),
//                             ),
//                             Expanded(
//                               child: NeumorphicDarkTextField(
//                                 hintText: 'Password',
//                               ),
//                             ),
//                           ],
//                         ),

//                         NeumorphicDarkButton(
//                           onTap: () {
//                             Navigator.pushNamed(
//                               context,
//                               Routes.launcherSignInPage,
//                             );
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                             child: Row(
//                               spacing: 10,
//                               children: <Widget>[
//                                 Expanded(
//                                   child: FusionAppText(
//                                     text: 'Log in',
//                                     style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),

//                                 Container(
//                                   height: 28,
//                                   width: 47,
//                                   decoration: BoxDecoration(
//                                     color: FusionDarkColorPallette.green20,
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: const Icon(
//                                     LucideIcons.arrowRight,
//                                     color: Colors.white,
//                                     size: 12,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class NeumorphicDarkTextField extends StatelessWidget {
//   final String? hintText;
//   final double borderRadius;
//   const NeumorphicDarkTextField({super.key, this.hintText, this.borderRadius = 12});

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(borderRadius),
//       child: Container(
//         margin: const EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           boxShadow: <BoxShadow>[
//             const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
//             const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
//             const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
//           ],
//           borderRadius: BorderRadius.circular(borderRadius),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(borderRadius),
//           child: TextFormField(
//             style: Theme.of(context).textTheme.labelLarge,
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: const Color(0xFF282826),
//               border: InputBorder.none,
//               enabledBorder: InputBorder.none,
//               focusedBorder: InputBorder.none,
//               hintText: hintText,
//               hoverColor: Colors.transparent,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//               hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class NeumorphicDarkButton extends StatefulWidget {
//   final String? text;
//   final Widget? child;
//   final VoidCallback? onTap;
//   final double borderRadius;
//   const NeumorphicDarkButton({
//     super.key,
//     this.text,
//     this.borderRadius = 12,
//     this.child,
//     this.onTap,
//   });

//   @override
//   State<NeumorphicDarkButton> createState() => _NeumorphicDarkButtonState();
// }

// class _NeumorphicDarkButtonState extends State<NeumorphicDarkButton> {
//   bool isPressed = false;

//   @override
//   Widget build(BuildContext context) {
//     assert(widget.text != null || widget.child != null);

//     return GestureDetector(
//       onTapDown: (_) => setState(() => isPressed = true),
//       onTapCancel: () => setState(() => isPressed = false),
//       onTapUp: (_) {
//         setState(() => isPressed = false);
//         widget.onTap?.call();
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: double.infinity,
//         height: 44,
//         margin: const EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           boxShadow: <BoxShadow>[
//             if (isPressed) ...<BoxShadow>[
//               const BoxShadow(color: Colors.black54, blurRadius: 1, offset: Offset(-2, -2), blurStyle: BlurStyle.inner),
//               const BoxShadow(color: Colors.white12, blurRadius: 1, offset: Offset(2, 2), blurStyle: BlurStyle.inner),
//               const BoxShadow(color: FusionDarkColorPallette.dark70, blurRadius: 4, blurStyle: BlurStyle.inner),
//             ] else ...<BoxShadow>[
//               const BoxShadow(color: Colors.black, blurRadius: 1, offset: Offset(0.5, 1)),
//               const BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-0.5, -1)),
//             ],
//           ],
//           borderRadius: BorderRadius.circular(widget.borderRadius),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(widget.borderRadius),
//           child: Container(
//             decoration: BoxDecoration(
//               color: const Color(0xFF232523),
//               borderRadius: BorderRadius.circular(widget.borderRadius),
//             ),
//             child: Center(
//               child: widget.child ?? FusionAppText(text: widget.text!),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
