part of 'project_work_area_appbar.dart';
class _AppBarContent extends StatelessWidget {
  const _AppBarContent({ required this.tabController, required this.currentTabs});
  final TabController tabController;
  final List<Widget> currentTabs;
  @override
  Widget build(BuildContext context) {
    return FusionFlatContainer(
      semanticsId: FusionTestKeys.instance.projectWorkAreaAppBar,
      height: double.maxFinite,
      color: context.colorScheme.elevation1,
      padding: const EdgeInsets.all(0),

      child: Row(
        children: <Widget>[
          Expanded(
            child: TabBar(
              labelColor: context.colorScheme.primaryWhite,
              unselectedLabelColor: context.colorScheme.elevation5,
              dividerColor: Colors.transparent,
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,

              indicator: BoxDecoration(color: context.colorScheme.elevation2, borderRadius: const BorderRadius.all(Radius.circular(8))),
              indicatorPadding: const EdgeInsets.only(
                top: 6,
                bottom: 6,
                left: 6,
                right: 6,
              ),
              indicatorSize: TabBarIndicatorSize.tab,

              labelStyle: context.textTheme.bodyMedium,
              unselectedLabelStyle: context.textTheme.bodyMedium,
              tabs: currentTabs,
            ),
          ),
          const _WorkAreaAppbarAction(),
        ],
      ),
    );
  }
}
