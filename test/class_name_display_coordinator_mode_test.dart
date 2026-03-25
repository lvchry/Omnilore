import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/widgets/class_name_display.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';

void main() {
  testWidgets('equal coordinator mode highlights both picks in green',
      (WidgetTester tester) async {
    final scheduling = Scheduling();

    await tester.pumpWidget(MaterialApp(
      home: ClassNameDisplay(
        currentRow: RowType.className,
        currentClass: 'TEST',
        schedule: scheduling,
        people: const ['Alice', 'Bob'],
        coordinatorMode: 'equal',
      ),
    ));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Alice'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Bob'));
    await tester.pump();

    final aliceButton =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Alice'));
    final bobButton =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Bob'));

    final aliceColor = aliceButton.style?.backgroundColor?.resolve({});
    final bobColor = bobButton.style?.backgroundColor?.resolve({});

    expect(aliceColor, Colors.green);
    expect(bobColor, Colors.green);
  });

  testWidgets('show coordinators renders equal coordinators as green and green',
      (WidgetTester tester) async {
    final scheduling = Scheduling();
    scheduling.courseControl.setEqualCoCoordinator('TEST', 'Alice');
    scheduling.courseControl.setEqualCoCoordinator('TEST', 'Bob');

    final key = GlobalKey<ClassNameDisplayState>();

    await tester.pumpWidget(MaterialApp(
      home: ClassNameDisplay(
        key: key,
        currentRow: RowType.className,
        currentClass: 'TEST',
        schedule: scheduling,
        people: const ['Alice', 'Bob'],
        coordinatorMode: 'none',
      ),
    ));

    key.currentState!.showCoordinators();
    await tester.pump();

    final aliceButton =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Alice'));
    final bobButton =
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Bob'));

    final aliceColor = aliceButton.style?.backgroundColor?.resolve({});
    final bobColor = bobButton.style?.backgroundColor?.resolve({});

    expect(aliceColor, Colors.green);
    expect(bobColor, Colors.green);
  });
}
