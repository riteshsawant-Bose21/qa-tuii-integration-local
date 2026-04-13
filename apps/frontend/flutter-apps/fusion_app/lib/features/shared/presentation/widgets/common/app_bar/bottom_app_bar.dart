import 'package:flutter/material.dart';
import 'package:fusion_app/features/control_pal/models/control_pal_model.dart';
import 'package:fusion_app/features/control_pal/presentation/control_pal_screen.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/nav_item.dart';

class CommonBottomNavigation<T> extends StatelessWidget {
  final List<BottomNavItemModel> bottomNavItems;
  final ValueNotifier<T> selectedTab;
  const CommonBottomNavigation({super.key, required this.selectedTab,required this.bottomNavItems});





  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        color: const Color(0xFF1A1A18),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
            height: 72,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(bottomNavItems.length, (index) {
                  return ValueListenableBuilder<T>(
                      valueListenable: selectedTab,
                      builder: (_, current, __) {
                        final active = current == bottomNavItems[index].selected;


                        return GestureDetector(
                          onTap: () {
                            selectedTab.value = bottomNavItems[index].selected;
                          },
                          child: NavItem(
                              selected: active,
                              item: bottomNavItems[index]
                          ),
                        );
                      }
                  );
                }
                ))));
  }
}