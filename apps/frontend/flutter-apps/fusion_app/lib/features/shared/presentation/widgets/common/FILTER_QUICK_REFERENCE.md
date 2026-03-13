# Filter Widget - Quick Reference Card

## 🔥 Copy & Paste This (2 minutes setup)

```dart
import 'package:fusion_app/features/shared/presentation/widgets/common/filter_bottom_sheet.dart';

class YourPage extends StatefulWidget {
  @override
  State<YourPage> createState() => _YourPageState();
}

class _YourPageState extends State<YourPage> {
  Map<String, List<String>> filters = {};

  void _showFilter() {
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
              FilterOption(name: 'Zone 1'),
              FilterOption(name: 'Zone 2'),
              FilterOption(name: 'Zone 3'),
            ],
          ),
          FilterCategory(
            name: 'Type',
            options: [
              FilterOption(name: 'Reception'),
              FilterOption(name: 'Fitness'),
              FilterOption(name: 'Cardio'),
            ],
          ),
          FilterCategory(
            name: 'Features',
            options: [
              FilterOption(name: 'Studio Platinum'),
              FilterOption(name: 'Equipment location'),
            ],
          ),
        ],
        initialSelectedFilters: filters,
        onApply: (selectedFilters) {
          setState(() => filters = selectedFilters);
          _fetchData(filters);  // Call your API/update UI
          Navigator.pop(context);
        },
        onClearFilters: () {
          setState(() => filters.clear());
          _fetchData({});
        },
      ),
    );
  }

  Future<void> _fetchData(Map<String, List<String>> filters) async {
    // TODO: API call or data fetch with filters
    print('Filters: $filters');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilter,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (filters.values.any((list) => list.isNotEmpty))
              Column(
                children: filters.entries.map((e) {
                  if (e.value.isEmpty) return SizedBox.shrink();
                  return Text('${e.key}: ${e.value.join(", ")}');
                }).toList(),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showFilter,
              child: Text('Open Filter'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📚 5 Minute Setup Variations

### With Loading State
```dart
onApply: (filters) async {
  setState(() => isLoading = true);
  try {
    final data = await api.fetch(filters);
    setState(() {
      results = data;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
  }
  Navigator.pop(context);
}
```

### With Provider
```dart
onApply: (filters) {
  context.read<FilterProvider>().setFilters(filters);
  Navigator.pop(context);
}
```

### With Bloc
```dart
onApply: (filters) {
  context.read<FilterBloc>().add(ApplyFiltersEvent(filters));
  Navigator.pop(context);
}
```

### Minimal (No State)
```dart
onApply: (filters) {
  print('Filters: $filters');
  Navigator.pop(context);
}
```

---

## 🎨 Common Filter Categories

### E-Commerce
```dart
FilterCategory(name: 'Category', options: [...]),
FilterCategory(name: 'Price', options: [...]),
FilterCategory(name: 'Rating', options: [...]),
FilterCategory(name: 'Availability', options: [...]),
```

### Real Estate
```dart
FilterCategory(name: 'Type', options: [...]),
FilterCategory(name: 'Bedrooms', options: [...]),
FilterCategory(name: 'Amenities', options: [...]),
```

### Fitness/Gym
```dart
FilterCategory(name: 'Zones', options: [...]),
FilterCategory(name: 'Type', options: [...]),
FilterCategory(name: 'Features', options: [...]),
```

### Job Search
```dart
FilterCategory(name: 'Category', options: [...]),
FilterCategory(name: 'Level', options: [...]),
FilterCategory(name: 'Location', options: [...]),
FilterCategory(name: 'Salary', options: [...]),
```

---

## ⚡ Quick API

### Constructor
```dart
FilterBottomSheet(
  title: 'FILTERS',                              // String, default: 'FILTERS'
  categories: List<FilterCategory>,              // Required
  onApply: (Map<String, List<String>>) {},      // Required callback
  onClearFilters: () {},                         // Optional callback
  initialSelectedFilters: {...},                 // Optional: pre-select
)
```

### Return Value (onApply)
```dart
Map<String, List<String>> {
  'Category Name': ['Selected Option 1', 'Selected Option 2'],
  'Another Category': ['Option A'],
}
```

### Creating Categories
```dart
FilterCategory(
  name: 'Display Name',
  options: [
    FilterOption(name: 'Option 1', id: '1'),
    FilterOption(name: 'Option 2', id: '2'),
  ],
)
```

---

## 🔧 Customization

### Custom Colors
Modify `lib/fusion_theme/app_theme.dart` - widget uses theme automatically

### Custom Icons
The search icon can be changed in source (default: `Icons.search`)

### Custom Font
Modify typography in `app_theme.dart` - uses `TextTheme` extensions

### Add Animations
Wrap showModalBottomSheet with animation builders

---

## ✅ Testing Checklist

- [ ] Filter opens on button tap
- [ ] Categories display with options
- [ ] Checkboxes can be toggled
- [ ] "Select All" works
- [ ] Search filters options real-time
- [ ] "Apply" button fires callback
- [ ] "Clear Filters" resets selection
- [ ] Colors match your theme
- [ ] Text is readable
- [ ] Works on mobile/tablet
- [ ] No console errors

---

## 🚨 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Colors wrong | Check app uses `FusionAppTheme.darkTheme` |
| Text not visible | Verify theme contrast settings |
| Not responding | Check callbacks are defined |
| Search not working | Verify option names match search |
| Filter not showing | Ensure categories have options |
| State not updating | Call `setState()` in onApply |

---

## 📊 Common Patterns

### Pattern 1: Simple State Update
```dart
onApply: (filters) {
  setState(() => selectedFilters = filters);
  Navigator.pop(context);
}
```

### Pattern 2: With Data Fetch
```dart
onApply: (filters) {
  final data = myRepository.getFiltered(filters);
  setState(() => results = data);
  Navigator.pop(context);
}
```

### Pattern 3: With External State
```dart
onApply: (filters) {
  context.read<MyProvider>().update(filters);
  Navigator.pop(context);
}
```

### Pattern 4: With Multiple Callbacks
```dart
onApply: (filters) {
  _saveFilters(filters);
  _fetchData(filters);
  _updateUI(filters);
  Navigator.pop(context);
}
```

---

## 📁 File Locations

| File | Purpose | Use For |
|------|---------|---------|
| `filter_bottom_sheet.dart` | Main widget | Import & use |
| `filter_bottom_sheet_example.dart` | Basic example | Learning |
| `filter_advanced_examples.dart` | Real examples | Reference |
| `filter_integration_examples.dart` | Copy-paste code | Quick start |
| `FILTER_README.md` | Full docs | Reference |
| `FILTER_IMPLEMENTATION_GUIDE.md` | Setup guide | Getting started |
| `FILTER_MANIFEST.md` | Navigation | Finding things |

---

## 🚀 Time Estimates

| Task | Time |
|------|------|
| Copy template above | 2 min |
| Customize categories | 3 min |
| Connect to data | 5 min |
| Test | 5 min |
| **Total** | **15 min** |

---

## 💡 Pro Tips

1. Start with the template above
2. Replace categories with your data
3. Handle the callback for your use case
4. Test with real data
5. Add error handling
6. Consider loading states

---

## 🎯 What's Included

✅ Main widget (filter_bottom_sheet.dart)  
✅ 4 example apps with different use cases  
✅ 5 copy-paste code examples  
✅ Full API documentation  
✅ Quick start guide  
✅ Troubleshooting guide  
✅ Design specifications  

---

## 📞 Next Steps

1. **Copy** the template above into your widget
2. **Replace** categories with your data
3. **Handle** the onApply callback
4. **Test** with your data
5. **Deploy** 🚀

---

## 📖 Learn More

- Full API: See `FILTER_README.md`
- Setup Guide: See `FILTER_IMPLEMENTATION_GUIDE.md`
- File Guide: See `FILTER_MANIFEST.md`
- Examples: See `filter_integration_examples.dart`

---

**Version:** 1.0  
**Status:** Production Ready ✅  
**Created:** March 3, 2026

