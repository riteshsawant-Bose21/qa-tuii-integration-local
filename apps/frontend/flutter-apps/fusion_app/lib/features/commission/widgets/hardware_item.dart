import 'package:flutter/material.dart';
import 'package:fusion_app/core/services/loader_service.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/checkbox_field.dart';
import 'package:fusion_lib/fusion_lib.dart' hide FusionToast;
import '../../shared/presentation/widgets/common/toast.dart';
class HardwareItem extends StatefulWidget {
  final int index;
  final String title;
  final String? ipAddress;
  final ValueNotifier<int?> selectedIndex;
  final Function? onSelected;

   HardwareItem({super.key,
    required this.index,
    required this.title,
    this.ipAddress,
    required this.selectedIndex,
    this.onSelected,
  });

  @override
  State<HardwareItem> createState() => _HardwareItemState();
}

class _HardwareItemState extends State<HardwareItem> {
  bool shouldShowError = true;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: widget.selectedIndex,
      builder: (_, current, __) {
        final isSelected = current == widget.index;

        return GestureDetector(
          onTap: () {
            widget.selectedIndex.value = widget.index;
            widget.onSelected!(widget.index);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:  isSelected
                  ? context.colorScheme.elevation2
                  : context.colorScheme.elevation1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:context.colorScheme.strokeLight,
              ),
            ),
            child: Row(
              children: [
                CommonCheckBox(isSelected: isSelected),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.b3Medium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.colorScheme.textPrimary,
                        ),
                      ),
                      if(widget.ipAddress!=null)...[
                      SizedBox(height: 4,),
                      Text(
                        widget.ipAddress!,
                        style: Theme.of(context).textTheme.l1Regular.copyWith(
                          fontWeight: FontWeight.w400,
                          color: context.colorScheme.textBody,
                        ),
                      ),
                     ]
                    ],
                  ),
                ),
                isLoading ?  Container(
                    width: 24,
                    height: 24,
                    child: ArcLoader(strokeWidth: 2,)) : GestureDetector(
                  onTap: () {
                    isLoading = true;
                    setState(() {

                    });

                    Future.delayed(Duration(seconds: 2),(){
                      isLoading = false;
                      if(shouldShowError){
                        shouldShowError = false;
                        FusionToast.show(
                          context,
                          message: "Unable to identify the device, try again",icon: Icons.error,
                          textColor: context.colorScheme.textPrimary,
                          iconColor: context.colorScheme.errorText,
                          backgroundColor: context.colorScheme.errorFill,
                        );
                      }
                      setState(() {});
                    });
                  },
                  child:  Icon(
                    Icons.lightbulb_outline,
                    color: context.colorScheme.iconWhite,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}