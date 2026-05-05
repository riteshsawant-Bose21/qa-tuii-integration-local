// part of '../create_zone_popup.dart';
//
// class CreateSubzoneWidget extends StatefulWidget {
//   const CreateSubzoneWidget({super.key});
//
//   @override
//   State<CreateSubzoneWidget> createState() => _CreateSubzoneWidgetState();
// }
//
// class _CreateSubzoneWidgetState extends State<CreateSubzoneWidget> {
//   final List<TextEditingController> _subZoneNameControllers = <TextEditingController>[];
//   late final CreateZoneViewModel createZoneViewModel = context.read<CreateZoneViewModel>();
//
//   void _addSubzone() {
//     createZoneViewModel.addSubzone();
//     _subZoneNameControllers.add(TextEditingController(text: "Untitled subzone"));
//   }
//
//   void _removeSubzone(int index) {
//     createZoneViewModel.removeSubzone(index);
//     _subZoneNameControllers.removeAt(index).dispose();
//   }
//
//   @override
//   void dispose() {
//     for (final TextEditingController controller in _subZoneNameControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
//       buildWhen: (CreateZoneViewModelState previous, CreateZoneViewModelState current) {
//         return previous.subzones != current.subzones;
//       },
//       builder: (BuildContext context, CreateZoneViewModelState state) {
//         final int subzoneCount = state.subzones.length;
//
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             if (subzoneCount > 0) ...<Widget>[
//               ...List<Widget>.generate(subzoneCount, (int subZoneIndex) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 4),
//                   child: SemanticHelper.formControl(
//                         testId: SemanticHelper.createTestId(SemanticTypes.textInput, "subzone_$subZoneIndex"),
//                         child:Row(
//                     children: <Widget>[
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: <Widget>[
//                             SemanticHelper.formControl(
//                               testId: SemanticHelper.createTestId(SemanticTypes.textInput, "create_subzone_name_input_$subZoneIndex"),
//                               child: PropertyTextField(
//                                 controller: _subZoneNameControllers[subZoneIndex],
//                                 onChanged: (String value) => context.read<CreateZoneViewModel>().onSubzoneNameChanged(subZoneIndex, value),
//                                 contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//                                 hintText: 'Enter subzone name',
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//
//                             // select listening areas for subzone
//                             _buildListeningAreaSelectionSection(context, subZoneIndex: subZoneIndex),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       MouseRegion(
//                         cursor: SystemMouseCursors.click,
//                         child: GestureDetector(
//                           onTap: () => _removeSubzone(subZoneIndex),
//                           child: SemanticHelper.button(
//                             testId: SemanticHelper.createTestId(SemanticTypes.button, "create_subzone_remove_button_$subZoneIndex"),
//                             child: Icon(
//                               Icons.close,
//                               color: context.colorScheme.iconDefault,
//                               size: 16,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   ),
//                 );
//               }),
//               const SizedBox(height: 12),
//             ],
//             SemanticHelper.button(
//               testId: SemanticHelper.createTestId(SemanticTypes.button, "create_subzone_add_button"),
//               child: MouseRegion(
//                 cursor: SystemMouseCursors.click,
//                 child: GestureDetector(
//                   onTap: _addSubzone,
//                   child: Row(
//                     children: <Widget>[
//                       Icon(
//                         LucideIcons.plus200,
//                         size: FusionSizes.iconSize16,
//                         color: context.colorScheme.primaryWhite,
//                       ),
//                       const SizedBox(width: 2),
//                       Expanded(
//                         child: FusionAppText(
//                           text: "Create Subzone",
//                           style: context.textTheme.bodySmall?.copyWith(
//                             color: context.colorScheme.onSurface,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
part of '../create_zone_content.dart';

class _CreateSubzoneWidget extends StatefulWidget {
  final ValueNotifier<bool> saveEnabledNotifier;
  final VoidCallback onRevalidate; // ← add

  const _CreateSubzoneWidget({
    required this.saveEnabledNotifier,
    required this.onRevalidate, // ← add
  });

  @override
  State<_CreateSubzoneWidget> createState() => _CreateSubzoneWidgetState();
}

class _CreateSubzoneWidgetState extends State<_CreateSubzoneWidget> {
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();
  final ValueNotifier<bool> _canAddSubzone = ValueNotifier<bool>(true);

  int? _draftIndex;
  int? _editingIndex;
  final List<TextEditingController> _nameControllers = <TextEditingController>[];
  final TextEditingController _formNameCtrl = TextEditingController();

  @override
  void dispose() {
    _canAddSubzone.dispose();
    for (final TextEditingController c in _nameControllers) c.dispose();
    _formNameCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  void _enterSetupMode() {
    final CreateZoneViewModel vm = context.read<CreateZoneViewModel>();
    vm.addSubzone();
    final int draftIdx = vm.state.subzones.length - 1;
    final String draftName = 'SubZone ${draftIdx + 1}';
    _nameControllers.add(TextEditingController(text: draftName));
    setState(() {
      _draftIndex = draftIdx;
      _editingIndex = null;
      _formNameCtrl.text = draftName;
    });
    widget.saveEnabledNotifier.value = false;
  }

  void _exitSetupMode() {
    if (_draftIndex != null) {
      context.read<CreateZoneViewModel>().removeSubzone(_draftIndex!);
      _nameControllers.removeAt(_draftIndex!).dispose();
    }
    setState(() {
      _draftIndex = null;
      _editingIndex = null;
      _formNameCtrl.clear();
    });
    widget.onRevalidate(); // ← not blindly true
    _canAddSubzone.value = true;
  }

  void _confirmDraft() {
    final String name = _formNameCtrl.text.trim();
    if (name.isEmpty) return;
    final CreateZoneViewModel vm = context.read<CreateZoneViewModel>();
    _nameControllers[_draftIndex!].text = name;
    vm.onSubzoneNameChanged(_draftIndex!, name);

    final int newConfirmedCount = _draftIndex! + 1;

    if (newConfirmedCount < 2) {
      // Minimum 2 required — auto-open the next draft so user is guided to add 2nd
      vm.addSubzone();
      final int nextDraft = vm.state.subzones.length - 1;
      final String nextName = 'SubZone ${nextDraft + 1}';
      _nameControllers.add(TextEditingController(text: nextName));
      setState(() {
        _draftIndex = nextDraft;
        _editingIndex = null;
        _formNameCtrl.text = nextName;
      });
    } else {
      setState(() {
        _draftIndex = null;
        _editingIndex = null;
        _formNameCtrl.clear();
      });
      widget.onRevalidate(); // ← not blindly true
      _canAddSubzone.value = true;
    }
  }

  void _startEditing(int index) => setState(() {
    _editingIndex = index;
    _formNameCtrl.text = _nameControllers[index].text;
  });

  void _saveEdit() {
    final String name = _formNameCtrl.text.trim();
    if (name.isEmpty) return;
    final CreateZoneViewModel vm = context.read<CreateZoneViewModel>();
    _nameControllers[_editingIndex!].text = name;
    vm.onSubzoneNameChanged(_editingIndex!, name);
    setState(() {
      _editingIndex = null;
      _formNameCtrl.text = _nameControllers[_draftIndex!].text;
    });
  }

  void _removeSubzone(int index) {
    context.read<CreateZoneViewModel>().removeSubzone(index);
    _nameControllers.removeAt(index).dispose();
    setState(() {
      _editingIndex = null;
      if (_draftIndex != null) {
        if (index < _draftIndex!) _draftIndex = _draftIndex! - 1;
        _formNameCtrl.text = _nameControllers[_draftIndex!].text;
      }
    });
  }

  String _buildSubtitle(CreateZoneViewModelState state, int index) {
    if (index >= state.subzones.length) return '';
    final List<ListeningArea> areas = state.subzones[index].listeningAreas;
    if (areas.isEmpty) return 'No areas selected';
    return areas
        .map((ListeningArea a) {
          final FloorModel? floor = _projectViewModel.getFloorForListeningArea(areaId: a.id);
          return '${floor?.name ?? '?'} • ${a.name}';
        })
        .join('  •  ');
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
      buildWhen: (CreateZoneViewModelState p, CreateZoneViewModelState c) => p.subzones != c.subzones,
      builder:
          (BuildContext context, CreateZoneViewModelState state) =>
              (_draftIndex == null && _nameControllers.isEmpty) ? _buildEntryButton(context) : _buildSetupPanel(context, state),
    );
  }

  // ── "+ Add SubZones" entry button ────────────────────────────

  Widget _buildEntryButton(BuildContext context) {
    return FusionIconTextButton(
      icon: LucideIcons.plus,
      label: 'Add SubZones',
      semanticId: 'add_subzones_entry_button',
      iconSize: 16,
      onTap: _enterSetupMode,
      style: context.textTheme.l1SemiBold.copyWith(color: context.colorScheme.textPrimary),
      iconColor: context.colorScheme.iconWhite,
    );
  }

  // ── Full setup panel ─────────────────────────────────────────

  Widget _buildSetupPanel(BuildContext context, CreateZoneViewModelState state) {
    // confirmed = everything except the active draft slot (if any)
    final int confirmedCount = _draftIndex ?? _nameControllers.length;
    final bool hasDraft = _draftIndex != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Divider(color: context.colorScheme.strokeLight, thickness: 1, height: 1),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: FusionAppText(
                text: 'Set up SubZones',
                style: context.textTheme.b3Medium.copyWith(color: context.colorScheme.textPrimary),
              ),
            ),
            // Cancel only shown while draft form is open
            if (hasDraft)
              FusionHoverTextButton(
                label: 'Cancel',
                semanticId: 'subzone_setup_cancel',
                onTap: _exitSetupMode,
                style: context.textTheme.b3SemiBold.copyWith(color: context.colorScheme.textPrimary),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Confirmed cards — always visible
        ...List<Widget>.generate(confirmedCount, (int i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _editingIndex == i ? _buildEditForm(context, subzoneIndex: i) : _buildSubzoneCard(context, state, i),
          );
        }),

        if (_editingIndex == null) ...<Widget>[
          if (confirmedCount > 0) const SizedBox(height: 4),
          if (hasDraft)
            _buildDraftForm(context)
          else
            ValueListenableBuilder<bool>(
              valueListenable: _canAddSubzone,
              builder: (BuildContext context, bool canAdd, _) {
                return Opacity(
                  opacity: canAdd ? 1.0 : 0.4, // ← visually dimmed when disabled
                  child: IgnorePointer(
                    ignoring: !canAdd, // ← blocks taps when disabled
                    child: FusionIconTextButton(
                      icon: LucideIcons.plus,
                      label: 'Add SubZone',
                      semanticId: 'add_another_subzone_button',
                      iconSize: 16,
                      onTap: _enterSetupMode,
                      style: context.textTheme.l1SemiBold.copyWith(
                        color: context.colorScheme.textPrimary,
                      ),
                      iconColor: context.colorScheme.textPrimary,
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  // ── Confirmed subzone card ────────────────────────────────────

  Widget _buildSubzoneCard(BuildContext context, CreateZoneViewModelState state, int index) {
    final int confirmedCount = _draftIndex ?? _nameControllers.length;
    final bool canDelete = confirmedCount > 2;

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'subzone_card_$index'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.colorScheme.strokeLight, width: 1),
          color: context.colorScheme.elevation2,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: _nameControllers[index].text.isNotEmpty ? _nameControllers[index].text : 'SubZone ${index + 1}',
                    style: context.textTheme.b3SemiBold.withColor(context.colorScheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  FusionAppText(
                    text: _buildSubtitle(state, index),
                    style: context.textTheme.l1Regular.withColor(
                      context.colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (canDelete) ...<Widget>[
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, 'subzone_delete_$index'),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _removeSubzone(index),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FusionIcon.icon(LucideIcons.trash, size: 20, color: context.colorScheme.iconWhite),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            SemanticHelper.button(
              testId: SemanticHelper.createTestId(SemanticTypes.button, 'subzone_edit_$index'),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _startEditing(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FusionIcon.icon(Icons.edit_outlined, size: 16, color: context.colorScheme.iconWhite),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftForm(BuildContext context) => _buildSubzoneForm(context, subzoneIndex: _draftIndex!, onSave: _confirmDraft);

  Widget _buildEditForm(BuildContext context, {required int subzoneIndex}) => _buildSubzoneForm(context, subzoneIndex: subzoneIndex, onSave: _saveEdit);

  // ── Shared form layout ────────────────────────────────────────

  Widget _buildSubzoneForm(BuildContext context, {required int subzoneIndex, required VoidCallback onSave}) {
    final bool isDraft = subzoneIndex == _draftIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FusionLabeledField(
          label: 'Name',
          semanticId: 'subzone_name_$subzoneIndex',
          child: FusionBorderedTextField(
            controller: _formNameCtrl,
            semanticId: 'subzone_name_input_$subzoneIndex',
            hintText: 'Subzone name',
          ),
        ),
        const SizedBox(height: 20),
        Divider(thickness: 1, height: 0, color: context.colorScheme.strokeLight),
        const SizedBox(height: 20),
        _ZoneListeningAreaSection(
          subzoneIndex: subzoneIndex,
          onAddingAreaChanged: (bool isAdding) {
            _canAddSubzone.value = !isAdding;
            if (isAdding) {
              widget.saveEnabledNotifier.value = false;
            } else {
              widget.onRevalidate(); // ← revalidate when add form closes
            }
          },
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          // ← wrap with ValueListenableBuilder
          child: ValueListenableBuilder<bool>(
            valueListenable: _canAddSubzone,
            builder: (BuildContext context, bool canAdd, _) {
              return Opacity(
                opacity: canAdd ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !canAdd,
                  child: FusionAppButton(
                    semanticId: 'subzone_save_$subzoneIndex',
                    height: 32,
                    text: isDraft ? 'Add SubZone' : 'Update SubZone',
                    color: context.colorScheme.elevation2,
                    borderRadius: 8,
                    textstyle: context.textTheme.l1Medium.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                    onPressed: onSave,
                    style: FusionAppButtonStyle.primary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
