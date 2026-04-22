import 'package:flutter/material.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/divider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/info_field.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/text_field/text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final String hint;
  const SearchAppBar({super.key, required this.hint,required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colorScheme.primaryBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              onTap: (){
                Navigator.pop(context);
              },
              child: Icon(Icons.chevron_left,
                  color: context.colorScheme.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child:
            AppTextField(
              controller: controller,
              hint: hint,
              prefixIcon: GestureDetector(
                onTap: (){
                  Navigator.pop(context);
                },
                child: Icon(
                    Icons.search,
                    color: context.colorScheme.strokeLight),
              ),
              suffixIcon: GestureDetector(
                onTap: (){
                  controller.clear();
                },
                child: Icon(
                    Icons.close,
                    color: context.colorScheme.primaryBlack),
              ),
            )),
          ],
        ),
      ),
      bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.75),
          child: CommonDivider()
      )
    );
  }
}