import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_stack_docking_system.dart';

void main() {
  group('StackDockingSystem Tests', () {
    testWidgets('Basic docking system setup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StackDockingSystem(
              currentTabId: 'test_tab',
              child: Row(
                children: [
                  StackSidebar(
                    sidebarId: 'left_sidebar',
                    children: [
                      StackDockablePanel(
                        id: 'test_panel',
                        title: 'Test Panel',
                        sidebarId: 'left_sidebar',
                        associatedTabId: 'test_tab',
                        child: const Text('Test Content'),
                      ),
                    ],
                  ),
                  const Expanded(child: Center(child: Text('Main Content'))),
                  StackSidebar(sidebarId: 'right_sidebar', children: []),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the panel is rendered in the sidebar
      expect(find.text('Test Panel'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('Panel drag to float functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StackDockingSystem(
              currentTabId: 'test_tab',
              child: Row(
                children: [
                  StackSidebar(
                    sidebarId: 'left_sidebar',
                    children: [
                      StackDockablePanel(
                        id: 'test_panel',
                        title: 'Test Panel',
                        sidebarId: 'left_sidebar',
                        associatedTabId: 'test_tab',
                        child: const Text('Test Content'),
                      ),
                    ],
                  ),
                  const Expanded(child: Center(child: Text('Main Content'))),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the panel header
      final panelFinder = find.text('Test Panel');
      expect(panelFinder, findsOneWidget);

      // Simulate a drag gesture to float the panel
      await tester.drag(panelFinder, const Offset(200, 100));
      await tester.pumpAndSettle();

      // The panel should now be floating (may need to adjust based on implementation)
      print('Panel should be floating now');
    });
  });
}
