import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class BuildingCanvasOptionButton extends StatelessWidget {
  const BuildingCanvasOptionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: AspectRatio(
        aspectRatio: 1,
        child: FusionFlatContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FusionAppButton(
                onPressed: onTap,
                style: FusionAppButtonStyle.neumorphic,
                semanticId: "building_canvas_option_$title",
                height: 100,
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: FusionImageAuto(
                    path: 'assets/icons/building_page/$icon',
                    height: 32,
                    color: context.colorScheme.textPrimary,
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  FusionAppText(text: title, style: Theme.of(context).textTheme.h6Bold),
                  const SizedBox(height: 4),
                  FusionAppText(
                    text: description,
                    style: Theme.of(context).textTheme.l1Regular.copyWith(
                      color: context.colorScheme.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
