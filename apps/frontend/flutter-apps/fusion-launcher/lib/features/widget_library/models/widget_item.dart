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
      name: 'DropDown',
      category: WidgetCategory.dropdown,
    ),
  ];

  static List<WidgetItem> getWidgetsByCategory(WidgetCategory category) {
    return widgets
        .where((WidgetItem widget) => widget.category == category)
        .toList();
  }
}
