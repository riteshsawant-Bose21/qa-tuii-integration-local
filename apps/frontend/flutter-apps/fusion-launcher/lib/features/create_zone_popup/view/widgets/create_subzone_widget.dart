part of '../create_zone_popup.dart';

class CreateSubzoneWidget extends StatefulWidget {
  const CreateSubzoneWidget({super.key});

  @override
  State<CreateSubzoneWidget> createState() => _CreateSubzoneWidgetState();
}

class _CreateSubzoneWidgetState extends State<CreateSubzoneWidget> {
  final List<TextEditingController> _subZoneNameControllers = <TextEditingController>[];
  late final CreateZoneViewModel createZoneViewModel = context.read<CreateZoneViewModel>();

  void _addSubzone() {
    createZoneViewModel.addSubzone();
    _subZoneNameControllers.add(TextEditingController(text: "Untitled subzone"));
  }

  void _removeSubzone(int index) {
    createZoneViewModel.removeSubzone(index);
    _subZoneNameControllers.removeAt(index).dispose();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _subZoneNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
      buildWhen: (CreateZoneViewModelState previous, CreateZoneViewModelState current) {
        return previous.subzones != current.subzones;
      },
      builder: (BuildContext context, CreateZoneViewModelState state) {
        final int subzoneCount = state.subzones.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (subzoneCount > 0) ...<Widget>[
              ...List<Widget>.generate(subzoneCount, (int subZoneIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TextFormField(
                              controller: _subZoneNameControllers[subZoneIndex],
                              onChanged: (String value) => context.read<CreateZoneViewModel>().onSubzoneNameChanged(subZoneIndex, value),
                              decoration: InputDecoration(
                                hintText: 'Enter subzone name',
                                hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                hoverColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                fillColor: context.colorScheme.surface,
                                isDense: true,
                              ),
                              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                            ),
                            const SizedBox(height: 4),

                            // select listening areas for subzone
                            _buildListeningAreaSelectionSection(context, subZoneIndex: subZoneIndex),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _removeSubzone(subZoneIndex),
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.greyDark,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _addSubzone,
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.greyDark,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: FusionAppText(
                        text: "Create Subzone",
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
