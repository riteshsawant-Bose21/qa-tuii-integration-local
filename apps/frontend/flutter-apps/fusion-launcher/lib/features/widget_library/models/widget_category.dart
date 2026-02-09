enum WidgetCategory { buttons, textFields, dropdown }

extension WidgetCategoryExtension on WidgetCategory {
  String get displayName {
    switch (this) {
      case WidgetCategory.buttons:
        return 'Buttons';
      case WidgetCategory.textFields:
        return 'Text Fields';
      case WidgetCategory.dropdown:
        return 'DropDown';
    }
  }
}
