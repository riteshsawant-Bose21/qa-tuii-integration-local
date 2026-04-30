import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ProjectCard extends StatelessWidget {
  final ProjectData data;
  final Function? onClick;
  const ProjectCard({super.key, required this.data,this.onClick});


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        onClick!();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.4,
          decoration: BoxDecoration(
            color: context.colorScheme.elevation2,
          ),
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.asset(
                   // data.thumbnailUrl ??
                        "assets/ph_projects.png",
                    fit: BoxFit.fitHeight,
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: context.colorScheme.elevation3,
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 16,vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(data.projectName, style: Theme.of(context).textTheme.b3Bold.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.textPrimary,
                      )),
                      const SizedBox(height: 4),
                      Text(
                         // data.description!,
                          '15 minutes ago',
                          style:Theme.of(context).textTheme.l1Regular.copyWith(
                        fontWeight: FontWeight.w400,
                        color: context.colorScheme.textBody,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectCardModel{
  final String title;
  final String subtitle;
  final String assetPath;


  ProjectCardModel({required this.title,required this.subtitle,required this.assetPath});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectCardModel &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          subtitle == other.subtitle &&
          assetPath == other.assetPath;

  @override
  int get hashCode => Object.hash(title, subtitle,assetPath);

  @override
  String toString() {
    return 'ProjectCardModel{title: $title, subtitle: $subtitle, assetPath: $assetPath}';
  }
}

