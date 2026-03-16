import 'widget_category.dart';

class WidgetItem {
  final String name;
  final WidgetCategory category;

  const WidgetItem({
    required this.name,
    required this.category,
  });
}

class WidgetLibraryData {
  static final List<WidgetItem> widgets = <WidgetItem>[
    // Example 1: Elevated Button
    const WidgetItem(
      name: 'FusionAppButton',
      category: WidgetCategory.buttons,
    ),
    const WidgetItem(
      name: 'FusionTextField',
      category: WidgetCategory.textFields,
    ),
    const WidgetItem(
      name: 'RadioButton',
      category: WidgetCategory.buttons,
    ),
    const WidgetItem(
      name: 'FusionSwitch',
      category: WidgetCategory.buttons,
    ),
    const WidgetItem(
      name: 'DropDown',
      category: WidgetCategory.textFields,
    ),
    const WidgetItem(
      name: 'HoverDropdownButtonFormField',
      category: WidgetCategory.textFields,
    ),
    const WidgetItem(
      name: 'Popup',
      category: WidgetCategory.popup,
    ),
    const WidgetItem(
      name: 'CheckboxGroup',
      category: WidgetCategory.others,
    ),
    const WidgetItem(
      name: 'FusionContainer',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionDialog',
      category: WidgetCategory.others,
    ),
    const WidgetItem(
      name: 'FusionExpandableTileWidget',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionFlatContainer',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionHorizontalResizableWidget',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionSvgIcon',
      category: WidgetCategory.images,
    ),
    const WidgetItem(
      name: 'FusionImage',
      category: WidgetCategory.images,
    ),
    const WidgetItem(
      name: 'FusionProfileImage',
      category: WidgetCategory.images,
    ),
    const WidgetItem(
      name: 'FusionKeyboardWrapper',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionPopupMenu',
      category: WidgetCategory.popup,
    ),
    const WidgetItem(
      name: 'FusionShimmer',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'ReorderableRow',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'ReorderableColumn',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'ReorderableFlex',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionToast',
      category: WidgetCategory.others,
    ),
    const WidgetItem(
      name: 'FusionVerticalResizableWidget',
      category: WidgetCategory.container,
    ),
    const WidgetItem(
      name: 'FusionTable',
      category: WidgetCategory.others,
    ),
  ];

  static List<WidgetItem> getWidgetsByCategory(WidgetCategory category) {
    return widgets
        .where((WidgetItem widget) => widget.category == category)
        .toList();
  }
}
