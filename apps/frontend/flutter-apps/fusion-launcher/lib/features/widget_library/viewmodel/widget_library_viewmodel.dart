import 'package:flutter/material.dart';

import '../models/widget_category.dart';
import '../models/widget_item.dart';

class WidgetLibraryViewModel extends ChangeNotifier {
  WidgetItem? _selectedWidget;
  WidgetCategory? _selectedCategory;

  final Map<WidgetCategory, bool> _expandedCategories =
      <WidgetCategory, bool>{};

  // Getters
  WidgetItem? get selectedWidget => _selectedWidget;
  WidgetCategory? get selectedCategory => _selectedCategory;

  bool isCategoryExpanded(WidgetCategory category) {
    return _expandedCategories[category] ?? false;
  }

  void toggleCategory(WidgetCategory category) {
    _expandedCategories[category] = !(_expandedCategories[category] ?? false);

    // Select category when clicked
    _selectedCategory = category;
    _selectedWidget = null;

    notifyListeners();
  }

  void setSelectedWidget(WidgetItem widget) {
    _selectedWidget = widget;
    _selectedCategory = widget.category;

    notifyListeners();
  }

  List<WidgetItem> getWidgetsByCategory(WidgetCategory category) {
    return WidgetLibraryData.getWidgetsByCategory(category);
  }
}
