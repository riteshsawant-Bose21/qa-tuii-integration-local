import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/dashboard/presentation/pages/home_screen.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/bottomsheet_action.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/menu_item.dart';
import 'package:fusion_lib/fusion_lib.dart';

class MenuDrawer extends StatelessWidget {
   MenuDrawer({super.key});

  final List<MenuItemModel> drawerMenuItems = [
    MenuItemModel(
      icon: Icons.home_outlined,
      title: 'Home',
      showTrailingIcon: false,
      onTap: () {},
    ),
    // MenuItemModel(
    //   icon: Icons.grid_view_outlined,
    //   title: 'All Projects',
    //   onTap: () {},
    // ),
    MenuItemModel(
      icon: Icons.settings_outlined,
      title: 'Settings',
      onTap: () {
        navigate(Routes.settingsPage);
      },
    ),
    MenuItemModel(
      icon: Icons.person_outline,
      title: 'Profile',
      onTap: () {
        navigate(Routes.profilePage);
      },
    ),
    MenuItemModel(
      icon: Icons.feedback_outlined,
      title: 'Submit Feedback',
      showTrailingIcon: false,
      onTap: () {},
    ),
    MenuItemModel(
      icon: Icons.logout,
      title: 'Sign Out',
      showTrailingIcon: false,
      onTap: () {
        showDialog(
          context: globalNavigatorKey.currentState!.context,
          builder: (context) {
            return Container(

              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FusionConfirmationBottomSheet(
                      title: "Sign Out",
                      icon: Icons.question_mark,
                      iconBackgroundColor: context.colorScheme.zone1Fill,
                      subtitle: "Are you sure you want to sign out?",
                      content: null,
                      buttons: [
                        FusionBottomSheetButton(
                          text: "Cancel",
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        FusionBottomSheetButton(
                          text: "Sign Out",
                          isPrimary:true,
                          onPressed: () {
                            showData=false;
                            Navigator.pushNamedAndRemoveUntil(context, Routes.loginPage,
                                    (Route<dynamic> route) => false);
                          },
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  ];


  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonAppBar(
        title: 'Menu',
        dividerPadding: 0,
        leadingIcon: SizedBox(width: 16),
        actions: [
        GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child: Icon(Icons.close,color: context.colorScheme.primaryWhite))
      ],),
      body: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Drawer(
          backgroundColor: context.colorScheme.primaryBlack,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          child: Column(
            children: [
              SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 8),
                physics: ClampingScrollPhysics(),
                itemCount: drawerMenuItems.length,
                  itemBuilder: (BuildContext ctx, int i){
                  MenuItemModel item = drawerMenuItems[i];
                return MenuItem(
                  icon: item.icon,
                  title: item.title,
                  showTrailingIcon: item.showTrailingIcon,
                  onTap: (){
                    item.onTap();
                  });
                  },separatorBuilder: (BuildContext ctx, int i){
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CommonDivider(paddingValue: 8)
                  );

                }
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Build - v0.3.0-1',
                  style: context.textTheme.l1Regular.copyWith(
                    fontWeight: FontWeight.w400,
                    color: context.colorScheme.textBody,
                  ),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  static void navigate(String route) {
    Navigator.pushNamed(
      globalNavigatorKey.currentState!.context,
      route
    );

  }
}


