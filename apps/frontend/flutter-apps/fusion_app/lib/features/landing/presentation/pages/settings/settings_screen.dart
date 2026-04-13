import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/menu_item.dart';
import 'package:fusion_lib/fusion_lib.dart';
class SettingsScreen extends StatelessWidget {
   SettingsScreen({super.key});

  final List<MenuItemModel> settingsMenuItems = [
    MenuItemModel(
      icon: Icons.home_outlined,
      title: 'General',
      onTap: () {
        navigate(Routes.generalSettingPage);
      },
    ),
    MenuItemModel(
      icon: Icons.grid_view_outlined,
      title: 'Updates',
      onTap: () {
        navigate(Routes.updatesPage);
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: const CommonAppBar(title: 'Settings'),
        body:  Column(
          children: [
            SizedBox(height: 20,),
            ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 8),
                physics: ClampingScrollPhysics(),
                itemCount: settingsMenuItems.length,
                itemBuilder: (BuildContext ctx, int i){
                  MenuItemModel item = settingsMenuItems[i];
                  return MenuItem(
                      icon: null,
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
          ],
        ),
      ),
    );
  }

  static void navigate(page) {
    Navigator.pushNamed(
        globalNavigatorKey.currentState!.context,
        page
    );
  }
}