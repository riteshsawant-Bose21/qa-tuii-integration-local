enum WidgetCategory { text, buttons, textFields, popup, container, images, others }

extension WidgetCategoryExtension on WidgetCategory {
  String get displayName {
    switch (this) {
      case WidgetCategory.buttons:
        return 'Buttons';
      case WidgetCategory.popup:
        return 'Popup';
      case WidgetCategory.images:
        return 'Images';
      case WidgetCategory.container:
        return 'Containers';
      case WidgetCategory.others:
        return 'others';
      case WidgetCategory.textFields:
        return 'Text Fields';
      case WidgetCategory.text:
        return 'Text';
    }
  }
}
