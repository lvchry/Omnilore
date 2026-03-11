import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/widgets/names_display_mode.dart';

void main() {
  testWidgets('button labels match coordinator mode',
      (WidgetTester tester) async {
    // Test that button labels update correctly based on coordinator mode

    // In 'none' mode, button should say "Set C and CC"
    await tester.pumpWidget(const MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: null,
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'none',
      ),
    ));
    await tester.pump();
    expect(find.text('Set C and CC'), findsOneWidget);
    expect(find.text('Set CC1 and CC2'), findsOneWidget);

    // In 'main' mode, Set C button should say "Confirm"
    await tester.pumpWidget(const MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: null,
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'main',
      ),
    ));
    await tester.pump();
    expect(find.text('Confirm'), findsWidgets); // appears for Set C button
    expect(find.text('Set C and CC'), findsNothing);

    // In 'equal' mode, Set CC button should say "Confirm"
    await tester.pumpWidget(const MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: null,
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'equal',
      ),
    ));
    await tester.pump();
    expect(find.text('Confirm'), findsWidgets); // appears for Set CC button
    expect(find.text('Set CC1 and CC2'), findsNothing);
  });

  testWidgets('show coords button disabled in coordinator selection mode',
      (WidgetTester tester) async {
    // Test that Show Coord(s) button is disabled when coordinatorMode != 'none'

    await tester.pumpWidget(MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: () {},
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'main',
      ),
    ));
    await tester.pump();

    ElevatedButton showButton =
        tester.widget(find.widgetWithText(ElevatedButton, 'Show Coord(s)'));
    expect(showButton.onPressed, isNull, reason: 'button should be disabled');
  });

  testWidgets('show coords button enabled in normal mode',
      (WidgetTester tester) async {
    // Test that Show Coord(s) button is enabled when coordinatorMode == 'none'

    bool callbackInvoked = false;
    await tester.pumpWidget(MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: () {
          callbackInvoked = true;
        },
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'none',
      ),
    ));
    await tester.pump();

    ElevatedButton showButton =
        tester.widget(find.widgetWithText(ElevatedButton, 'Show Coord(s)'));
    expect(showButton.onPressed, isNotNull, reason: 'button should be enabled');

    await tester.tap(find.text('Show Coord(s)'));
    await tester.pump();
    expect(callbackInvoked, isTrue, reason: 'callback should be invoked');
  });

  testWidgets('all buttons rendered correctly', (WidgetTester tester) async {
    // Test that all expected buttons are present
    await tester.pumpWidget(MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: () {},
        onImplSplit: () {},
        onShowCoords: () {},
        onSetC: () {},
        onSetCC: () {},
        coordinatorMode: 'none',
      ),
    ));
    await tester.pump();

    expect(find.text('Show Splits'), findsOneWidget);
    expect(find.text('Imp. Splits'), findsOneWidget);
    expect(find.text('Show Coord(s)'), findsOneWidget);
    expect(find.text('Set C and CC'), findsOneWidget);
    expect(find.text('Set CC1 and CC2'), findsOneWidget);
    expect(find.text('NAMES DISPLAY MODE'), findsOneWidget);
  });
}
