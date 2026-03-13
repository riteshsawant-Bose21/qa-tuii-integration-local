# Filter Bottom Sheet Widget

A fully-featured, reusable filter bottom sheet widget for Flutter applications that integrates seamlessly with the Fusion App theme system.

## Features

✅ **Multi-Category Filters** - Organize filters into multiple categories (Zones, Type, Alerts, etc.)  
✅ **Search Functionality** - Real-time search across all filter options  
✅ **Select All / Deselect** - Quick selection/deselection of entire categories  
✅ **Theme Integration** - Full support for light and dark themes using the Fusion App color scheme  
✅ **Checkbox Selection** - Visual feedback with custom checkboxes  
✅ **Apply & Clear Actions** - Built-in buttons for applying or clearing filters  
✅ **Responsive Design** - Adapts to different screen sizes  

## Installation

The widget is located at:
```
lib/features/shared/presentation/widgets/common/filter_bottom_sheet.dart
```

## Usage

### Basic Example

```dart
import 'package:fusion_app/features/shared/presentation/widgets/common/filter_bottom_sheet.dart';

void _showFilterBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterBottomSheet(
      title: 'FILTERS',
      categories: [
        FilterCategory(
          name: 'Zones',
          options: [
            FilterOption(name: 'Select All', id: 'select_all'),
            FilterOption(name: 'Reception', id: 'reception'),
            FilterOption(name: 'Fitness', id: 'fitness'),
            FilterOption(name: 'Cardio', id: 'cardio'),
          ],
        ),
        FilterCategory(
          name: 'Type',
          options: [
            FilterOption(name: 'Equipment A', id: 'equip_a'),
            FilterOption(name: 'Equipment B', id: 'equip_b'),
          ],
        ),
      ],
      onApply: (selectedFilters) {
        // Handle filter selection
        print('Selected: $selectedFilters');
        // Typically fetch data with these filters
      },
      onClearFilters: () {
        // Handle clearing filters
        print('Filters cleared');
      },
    ),
  );
}
```

### With Initial Selection

```dart
FilterBottomSheet(
  title: 'FILTERS',
  categories: [...],
  initialSelectedFilters: {
    'Zones': ['Reception', 'Fitness'],
    'Type': ['Equipment A'],
  },
  onApply: (selectedFilters) { ... },
)
```

## API Reference

### FilterBottomSheet

Main widget for displaying filters in a bottom sheet.

#### Constructor Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `categories` | `List<FilterCategory>` | ✓ | List of filter categories |
| `onApply` | `Function(Map<String, List<String>>)` | ✓ | Callback when Apply is pressed |
| `onClearFilters` | `VoidCallback?` | ✗ | Callback when Clear Filters is pressed |
| `initialSelectedFilters` | `Map<String, List<String>>?` | ✗ | Pre-selected filters |
| `title` | `String` | ✗ | Header title (default: 'FILTERS') |

#### Methods

- `_toggleFilter(String categoryName, String optionName)` - Toggle a single filter option
- `_selectAllInCategory(String categoryName)` - Select all options in a category
- `_deselectAllInCategory(String categoryName)` - Deselect all options in a category
- `_clearAllFilters()` - Clear all selected filters

### FilterCategory

Model class for a filter category.

```dart
FilterCategory(
  name: 'Zones',  // Category name displayed in sidebar
  options: [
    FilterOption(name: 'Zone 1', id: 'zone_1'),
    FilterOption(name: 'Zone 2', id: 'zone_2'),
  ],
)
```

### FilterOption

Model class for individual filter options.

```dart
FilterOption(
  name: 'Reception',  // Display name
  id: 'reception',    // Unique identifier (optional)
)
```

## Theme Integration

The widget automatically uses the Fusion App theme colors and typography:

### Dark Theme Colors Used

| Element | Color | Hex Code |
|---------|-------|----------|
| Background | `elevation2` | `#292826` |
| Option Panel | `elevation3` | `#3D3C38` |
| Primary Text | `textPrimary` | `#FFFFFF` |
| Secondary Text | `textSecondary` | `#595752` |
| Borders | `strokeLight` | `#3D3C38` |
| Accent | `primaryColor` | `#2F7554` |

### Typography Used

- **Header**: `l1SemiBold` (12px, 600 weight)
- **Category Label**: `b3SemiBold` / `b3Regular` (14px)
- **Filter Option**: `b3Regular` / `b3SemiBold` (14px)
- **Search Hint**: `b2Regular` (16px)
- **Buttons**: `b2SemiBold` (16px)

## Styling Details

### Layout Structure

```
┌─────────────────────────────────────┐
│ FILTERS | (divider)                 │ ← Header
├─────────────────────────────────────┤
│ [🔍 Search across filters...]       │ ← Search
├──────────────┬──────────────────────┤
│   ZONES      │ ☑ Select All         │
│   (divider)  │ ☐ Reception          │
│   TYPE       │ ☐ Fitness            │
│   ALERTS     │ ─────────────────    │
│              │ ☐ Cardio             │
│              │ ☐ Weights            │
│              │ ─────────────────    │
│              │ ☑ Studio Platinum    │
├──────────────┴──────────────────────┤
│ [Clear Filters]  [  Apply  ]        │ ← Actions
└─────────────────────────────────────┘
```

### Checkbox States

- **Unchecked**: Border with `textDisabled` color
- **Checked**: Border with `primaryColor`, filled with indicator
- **Selected Text**: `primaryWhite`
- **Unselected Text**: `textBody`

## Design Specs (From Figma)

- **Bottom Sheet Dimensions**: 390px × 582px
- **Border Radius**: 20px (top corners only)
- **Padding**: 24px top, 16px sides, 40px bottom
- **Gap**: 16px between sections
- **Checkbox Size**: 16px × 16px
- **Border Radius**: 4px
- **Search Field Height**: 48px
- **Button Height**: 48px
- **Border Radius**: 12px

## State Management

The widget uses internal state management via `StatefulWidget`. For integration with larger state management solutions (Provider, Bloc, etc.), you can:

1. **Extract selected filters** from the `onApply` callback
2. **Update parent state** in the callback handler
3. **Pass initial filters** through `initialSelectedFilters` parameter

Example with Provider:

```dart
onApply: (selectedFilters) {
  context.read<FilterProvider>().setSelectedFilters(selectedFilters);
  Navigator.pop(context);
}
```

## Customization

### Custom Colors (if needed)

The widget uses theme-based colors. To customize, modify the color scheme in your theme file:
`lib/fusion_theme/app_theme.dart`

### Custom Typography

Typography is sourced from `TextTheme` extensions defined in `app_theme.dart`:
- `l1SemiBold` - Labels
- `b2SemiBold` - Buttons
- `b3Regular`/`b3SemiBold` - Options

### Custom Icons

To change the search icon, modify the `_buildSearchField` method:

```dart
Icon(
  Icons.search,  // Change this icon
  color: colorScheme.textPrimary,
  size: 24,
)
```

## Performance Considerations

- Uses `SingleChildScrollView` for scrollable filter options
- Efficient state updates with `setState`
- No unnecessary rebuilds - uses targeted widget updates
- Optimized search with `where()` filtering

## Accessibility

The widget provides:
- Clear text labels for all options
- Sufficient color contrast (meets WCAG AA standards)
- Adequate touch targets (minimum 16×16 for checkboxes)
- Semantic structure with proper hierarchy

## Browser/Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Known Limitations

1. Currently uses internal state - for Redux/Bloc integration, consider wrapping with a state management provider
2. Search is case-insensitive by default
3. Category names must be unique
4. Maximum recommended categories: 5 (due to sidebar width)

## Future Enhancements

- [ ] Add animation support
- [ ] Support for nested categories
- [ ] Custom category icons
- [ ] Drag-to-reorder filter categories
- [ ] Filter presets/saved filters
- [ ] Analytics integration

## Testing

The widget can be tested using Flutter's testing framework:

```dart
testWidgets('FilterBottomSheet displays categories', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: FusionAppTheme.darkTheme,
      home: Scaffold(
        body: FilterBottomSheet(
          categories: [
            FilterCategory(
              name: 'Test',
              options: [FilterOption(name: 'Option 1')],
            ),
          ],
          onApply: (_) {},
        ),
      ),
    ),
  );

  expect(find.text('Test'), findsOneWidget);
  expect(find.text('Option 1'), findsOneWidget);
});
```

## Troubleshooting

### Filters Not Appearing
- Ensure `categories` list is not empty
- Check that `FilterCategory` objects have options

### Theme Colors Not Applying
- Verify app is using `FusionAppTheme.darkTheme` or `FusionAppTheme.lightTheme`
- Check that `MaterialApp` wraps the widget

### Search Not Working
- Ensure filter option names match expected text
- Check that `searchQuery` state is being updated

## License

Part of the Fusion App project.

## Support

For issues or questions, refer to the example file:
`lib/features/shared/presentation/widgets/common/filter_bottom_sheet_example.dart`

