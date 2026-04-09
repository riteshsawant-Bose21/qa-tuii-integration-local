import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool bottomWidget;
  final double dividerPadding;
  final Widget? leadingIcon;
  final List<Widget> actions;

  const CommonAppBar({
    required this.title,
    this.leadingIcon,
    this.bottomWidget=true,
    this.dividerPadding=16,
    this.actions = const [
  ],super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colorScheme.primaryBlack,
      title: Text(title,
       style: context.textTheme.b2Medium!.copyWith(
        fontWeight: FontWeight.w500,
        color: context.colorScheme.textPrimary,
         ),
      ),
      leading:leadingIcon ??  GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child:  Icon(Icons.chevron_left,color: context.colorScheme.iconWhite,size: 24,
          )),
      leadingWidth: leadingIcon is SizedBox ? 16 : 48,
      titleSpacing: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
        // flexibleSpace: Align(
        //     alignment: Alignment.bottomCenter,
        //     child: Container(
        //       margin: EdgeInsetsGeometry.only(bottom: 0),
        //         child: CommonDivider(paddingValue: dividerPadding))),
      // bottom: bottomWidget ? const PreferredSize(
      //   preferredSize: Size.fromHeight(0.75),
      //   child: CommonDivider(paddingValue: 16)
      // ) :null,
      actions: [
        ...actions,
        SizedBox(width: 16),
      ]
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

