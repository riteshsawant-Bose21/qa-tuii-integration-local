part of '../create_zone_popup.dart';

class CreateSubzoneWidget extends StatefulWidget {
  const CreateSubzoneWidget({super.key});

  @override
  State<CreateSubzoneWidget> createState() => _CreateSubzoneWidgetState();
}

class _CreateSubzoneWidgetState extends State<CreateSubzoneWidget> {
  final List<TextEditingController> _subZoneNameControllers = <TextEditingController>[];

  void addUntitledSubzone() {
    setState(
      () => _subZoneNameControllers.add(
        TextEditingController(
          text: "Untitled Subzone ${_subZoneNameControllers.length + 1}",
        ),
      ),
    );
  }

  void removeSubzone(int index) {
    setState(() {
      final TextEditingController controller = _subZoneNameControllers.removeAt(index);
      controller.dispose(); // ✅ IMPORTANT
    });
  }

  int get subzoneCount => _subZoneNameControllers.length;

  @override
  void dispose() {
    for (final TextEditingController controller in _subZoneNameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (subzoneCount > 0) ...<Widget>[
          ...List<Widget>.generate(subzoneCount, (int index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _subZoneNameControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Enter zone name',
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
                        AddListeningAreasToZone(
                          selectedListeningAreaIds: <String>[],
                          onListeningAreaSelected: (List<String> newSelectedIds) {
                            // setState(() {
                            //   _selectedListeningAreaIds
                            //     ..clear()
                            //     ..addAll(newSelectedIds);
                            // });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => removeSubzone(index),
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
          const SizedBox(height: 8),
        ],
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: addUntitledSubzone,
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
  }
}
