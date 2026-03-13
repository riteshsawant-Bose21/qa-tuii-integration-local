import 'package:flutter/material.dart';
import 'package:fusion_app/features/project/presentation/configuration/widgets/db_slider.dart';
import 'package:fusion_app/features/shared/presentation/widgets/common/app_bar/app_bar.dart';
import 'package:fusion_app/features/zones/widgets/meter.dart';
import 'package:fusion_app/features/zones/widgets/zone_header.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ZonesScreen extends StatelessWidget {
  const ZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.primaryBlack,
      appBar: CommonAppBar(title: 'Zones'),
      body: _ZonesList()
    );
  }
}

class ZonePanel extends StatelessWidget {
  final String title;
  final Color headerColor;
  final bool expanded;
  final bool showCircuits;
  final Function onTap;

  const ZonePanel({
    super.key,
    required this.title,
    required this.headerColor,
    required this.onTap,
    this.expanded = false,
    this.showCircuits = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZoneHeader(title: title, color: headerColor,onTap: (){
            onTap!(1);
          },expanded: expanded,),

          SizedBox(height: 12,),


          if (expanded) ... [
            Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AudioMeterContainer()),
            SizedBox(height: 16,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: (){
                  onTap!(2);
                },
                child: Text(
                  showCircuits ? 'Hide Circuits' : 'View Circuits',
                  style: Theme.of(context).textTheme.l1SemiBold.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
            if (showCircuits) ... [
            SizedBox(height: 16,),
            Container(

              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(color: context.colorScheme.elevation2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
              child: _MeterRow2(label: 'DM8F'),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.colorScheme.elevation1,
                border: Border.all(color: context.colorScheme.elevation2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12,vertical: 12),
              child: _MeterRow2(label: 'DM8-SUB'),
            ),
            ]else
              SizedBox(height: 12,),
          ],
        ],
      ),
    );
  }
}

class _ZonesList extends StatefulWidget {
  const _ZonesList();

  @override
  State<_ZonesList> createState() => _ZonesListState();
}

class _ZonesListState extends State<_ZonesList> {


  final List<_ZoneData> _zones =  [
    _ZoneData('Reception', Color(0xFF2E3F63),expanded: true),
    _ZoneData('Fitness', Color(0xFF5A3428)),
    _ZoneData('Studio Gold', Color(0xFF1F5A43)),
    _ZoneData('Studio Platinum', Color(0xFF6A5A14)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        return ZonePanel(
          title: zone.title,
          headerColor: zone.color,
          expanded: zone.expanded,
          showCircuits: zone.showCircuits,
          onTap: (value) {
            setState(() {


              if(value==1){
                zone.expanded = !zone.expanded;
              }else{
                zone.showCircuits = !zone.showCircuits;
              }


            });
          },
        );
      },
    );
  }
}

class _ZoneData {
  final String title;
  final Color color;
  bool expanded;
  bool showCircuits;

   _ZoneData(this.title, this.color,{this.expanded=false,this.showCircuits=false});
}


class _MeterRow2 extends StatelessWidget {
  final String label;

  const _MeterRow2({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.speaker_outlined, size: 16,color:context.colorScheme.iconWhite),
            const SizedBox(width: 6),
            Text(label,
              style: Theme.of(context).textTheme.l1Regular.copyWith(
              fontWeight: FontWeight.w400,
              color:context.colorScheme.textSecondary,
            ),),

            const Spacer(),
             Icon(Icons.volume_up, color: context.colorScheme.iconWhite),
          ]
        ),
        const SizedBox(height: 6),
        AudioMeterContainer(),
      ],
    );
  }
}
