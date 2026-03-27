part of 'project_work_area_appbar.dart';

class _ProjectNameSection extends StatelessWidget {
  const _ProjectNameSection();

  @override
  Widget build(BuildContext context) {
    return FusionFlatContainer(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: <Widget>[
          /// Back Button
          SizedBox(
            width: 38,
            height: 48,

            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primaryWhite,
                size: 20,
              ),
              onPressed: () {
                serviceLocator<ProjectViewModel>().closeProject();
                Navigator.of(context).pop();
              },
              tooltip: 'Back to projects',
            ),
          ),

          /// Project Name Section
          InkWell(
            onTap: () => CreateNewProjectDialog.show(context, isEditMode: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              width: 197,

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                          builder: (
                            BuildContext context,
                            ProjectViewModelState state,
                          ) {
                            return FusionAppText(
                              text: serviceLocator<ProjectViewModel>().projectName,
                              semanticId: FusionTestKeys.projectName,
                              textOverflow: TextOverflow.ellipsis,
                              maxLine: 1,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        FusionAppText(
                          text: "1.0.0",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
