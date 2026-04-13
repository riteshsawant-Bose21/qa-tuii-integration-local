import 'package:flutter/material.dart';
import 'package:fusion_app/core/router/navigation_observer.dart';
import 'package:fusion_app/core/router/routes.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/menu_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_lib/fusion_lib.dart';
class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final List<ProfileMenuItem> items = [
    ProfileMenuItem(
     // icon: Icons.home_outlined,
      title: 'Personal Information',
      onTap: () {
        navigate(Routes.personalInfoPage);
      },
    ),
    ProfileMenuItem(
    //  icon: Icons.grid_view_outlined,
      title: 'Account Credentials',
      onTap: () {
        navigate(Routes.accountCredentialsInfoPage);
      },
    ),
    ProfileMenuItem(
    //  icon: Icons.settings_outlined,
      title: 'Contact & Location',
      onTap: () {
        navigate(Routes.addressPage);
      },
    ),
    ProfileMenuItem(
     // icon: Icons.person_outline,
      title: 'Preferences',
      onTap: () {
        navigate(Routes.preferencesPage);
      },
    ),
  ];


  @override
  Widget build(BuildContext context) {

    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: context.colorScheme.primaryBlack,
        appBar: CommonAppBar(title: 'Profile'),
        body: Column(
          children: [
            SizedBox(height: 20,),
            ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (BuildContext ctx, int i){
                  ProfileMenuItem item = items[i];
                  return MenuItem(
                    icon: null,
                    title: item.title,
                    showTrailingIcon: item.showTrailingIcon,
                    onTap: (){
                      item.onTap();
                    },
                  );
                },separatorBuilder: (BuildContext ctx, int i){
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                        child: CommonDivider(paddingValue: 8)
                    );
            }
            ),
          ],
        )
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


class ProfileMenuItem {
  //final IconData icon;
  final String title;
  final bool showTrailingIcon;
  final VoidCallback onTap;

  const ProfileMenuItem({
    //required this.icon,
    required this.title,
    required this.onTap,
    this.showTrailingIcon = true,
  });
}
