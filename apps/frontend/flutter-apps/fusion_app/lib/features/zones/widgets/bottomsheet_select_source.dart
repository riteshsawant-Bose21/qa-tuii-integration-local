import 'package:flutter/material.dart';
import 'package:fusion_app/features/commission/models/bluetooth_device_model.dart';
import 'package:fusion_app/features/commission/widgets/hardware_item.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/button.dart';
import 'package:fusion_app/features/zones/models/zone_source_model.dart';
import 'package:fusion_app/features/zones/widgets/source_item.dart';
import 'package:fusion_lib/fusion_lib.dart';

class BottomSheetSelectSource extends StatelessWidget {
  final ValueNotifier<int> selectedIndex;
  final Function? onSelected;
  final List<ZoneSourceModel> sources;
  const BottomSheetSelectSource({super.key,this.sources=const[], required this.selectedIndex,this.onSelected});

  @override
  Widget build(BuildContext context) {

    print("selectedIndex.value");
    print(selectedIndex.value);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:  [
                    Text(
                      'Select Source',
                      style:Theme.of(context).textTheme.b2Medium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),



                ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: sources.length,
                    itemBuilder: (ctx,i){


                      return ValueListenableBuilder<int>(
                          valueListenable: selectedIndex,
                          builder: (context, mode, _) {
                          return GestureDetector(
                              onTap: (){
                                selectedIndex.value = i;
                              },
                              child: SourceCard(
                                source: sources[i],
                                selected: selectedIndex.value == i,
                                showCheckbox: true,));
                        }
                      );
                    },
                    separatorBuilder:   (ctx,i){
                      return  const SizedBox(height: 12);
                    }
                ),

                const SizedBox(height: 20),
                CustomButton(
                  backGroundColor: context.colorScheme.elevation1,
                  isNeumorphic: true,
                  enabled: ValueNotifier(true),
                  onPressed: (){
                    onSelected!(selectedIndex.value);
                    Navigator.pop(context);
                  },
                  buttonText:'Save Changes',
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap:() =>  Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:context.colorScheme.elevation1,
              shape: BoxShape.circle,
              boxShadow:  [
                BoxShadow(
                  color: context.colorScheme.elevation1,
                  blurRadius: 12,
                ),
              ],
            ),
            child:  Icon(Icons.close, color:  context.colorScheme.onPrimary),
          ),
        )
      ],
    );
  }
}