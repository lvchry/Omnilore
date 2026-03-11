import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';
import 'package:omnilore_scheduler/widgets/class_name_display.dart';
import 'package:omnilore_scheduler/widgets/names_display_mode.dart';
import 'package:omnilore_scheduler/widgets/table/overview_row.dart';
// for RowType enum

void main() {
  testWidgets(
      're-entering Set C and CC allows selecting both new C and CC (no stale red highlight)',
      (WidgetTester tester) async {
    // build a real scheduling instance with test data so that the
    // coordinator-setting logic actually updates the data store.
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    // pick the first course code; the sample data contains plenty of people
    String course = scheduling.getCourseCodes().first;
    List<String> people =
        scheduling.overviewData.getPeopleForResultingClass(course).toList();
    expect(people.length, greaterThanOrEqualTo(4),
        reason: 'test resources should provide at least four people');

    // pump the widget under test
    await tester.pumpWidget(MaterialApp(
      home: ClassNameDisplay(
        currentRow: RowType.className,
        currentClass: course,
        schedule: scheduling,
        people: people,
        coordinatorMode: 'none',
      ),
    ));
    await tester.pumpAndSettle();

    // first assignment: choose people[0] as C and people[1] as CC
    await tester.tap(find.text('Set C and CC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[0]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[1]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    var coords = scheduling.courseControl.getCoordinators(course);
    expect(coords, isNotNull);
    expect(coords!.coordinators[0], people[0]);
    expect(coords.coordinators[1], people[1]);

    // re-enter selection mode and make a completely new pair
    await tester.tap(find.text('Set C and CC'));
    await tester.pumpAndSettle();

    // if the previous C had been left selected, the first tap below would
    // have ended up as a CC change and the final assert would fail; this
    // verifies our fix that selections are cleared when re-entering mode.
    await tester.tap(find.text(people[2]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[3]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    coords = scheduling.courseControl.getCoordinators(course);
    expect(coords, isNotNull);
    expect(coords!.coordinators[0], people[2]);
    expect(coords.coordinators[1], people[3]);
  });

  testWidgets(
      're-entering Set CC1 and CC2 allows selecting two fresh coordinators',
      (WidgetTester tester) async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    String course = scheduling.getCourseCodes().first;
    List<String> people =
        scheduling.overviewData.getPeopleForResultingClass(course).toList();
    expect(people.length, greaterThanOrEqualTo(4));

    await tester.pumpWidget(MaterialApp(
      home: ClassNameDisplay(
        currentRow: RowType.className,
        currentClass: course,
        schedule: scheduling,
        people: people,
        coordinatorMode: 'none',
      ),
    ));
    await tester.pumpAndSettle();

    // initial equal assignment: people[0], people[1]
    await tester.tap(find.text('Set CC1 and CC2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[0]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[1]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    var coords = scheduling.courseControl.getCoordinators(course);
    expect(coords, isNotNull);
    expect(coords!.equal, isTrue);
    expect(coords.coordinators[0], people[0]);
    expect(coords.coordinators[1], people[1]);

    // re-enter equal mode and pick two new ones
    await tester.tap(find.text('Set CC1 and CC2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[2]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[3]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    coords = scheduling.courseControl.getCoordinators(course);
    expect(coords, isNotNull);
    expect(coords!.equal, isTrue);
    expect(coords.coordinators[0], people[2]);
    expect(coords.coordinators[1], people[3]);
  });

  testWidgets('tapping displayed coordinator clears assignment',
      (WidgetTester tester) async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    String course = scheduling.getCourseCodes().first;
    List<String> people =
        scheduling.overviewData.getPeopleForResultingClass(course).toList();

    await tester.pumpWidget(MaterialApp(
      home: ClassNameDisplay(
        currentRow: RowType.className,
        currentClass: course,
        schedule: scheduling,
        people: people,
        coordinatorMode: 'none',
      ),
    ));
    await tester.pumpAndSettle();

    // set a main/co pair
    await tester.tap(find.text('Set C and CC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[0]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(people[1]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // now show them
    ClassNameDisplayState state =
        tester.state(find.byType(ClassNameDisplay));
    state.showCoordinators();
    await tester.pumpAndSettle();

    // confirm they are displayed (buttons should be green)
    expect(
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, people[0]))
            .style
            ?.backgroundColor
            ?.resolve({}),
        equals(Colors.green));

    // tap the displayed C should clear all coords
    await tester.tap(find.text(people[0]));
    await tester.pumpAndSettle();

    expect(scheduling.courseControl.getCoordinators(course), isNull);
  });

  testWidgets('show coords button disabled while selecting coordinators',
      (WidgetTester tester) async {
    var scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    String course = scheduling.getCourseCodes().first;
    List<String> people =
        scheduling.overviewData.getPeopleForResultingClass(course).toList();
    expect(people.length, greaterThanOrEqualTo(2));

    // put the display into selection mode and verify showCoordinators is a
    // no-op when called directly.
    await tester.pumpWidget(MaterialApp(
      home: ClassNameDisplay(
        currentRow: RowType.className,
        currentClass: course,
        schedule: scheduling,
        people: people,
        coordinatorMode: 'main',
      ),
    ));
    await tester.pumpAndSettle();
    ClassNameDisplayState state =
        tester.state(find.byType(ClassNameDisplay));
    expect(state.getSelectedC(), isNull);
    expect(state.getSelectedCC(), isNull);

    // assign some existing coordinators so showCoordinators would normally
    // update the selection
    scheduling.courseControl.setMainCoCoordinator(course, people[0]);
    scheduling.courseControl.setMainCoCoordinator(course, people[1]);

    state.showCoordinators();
    await tester.pumpAndSettle();
    expect(state.getSelectedC(), isNull);
    expect(state.getSelectedCC(), isNull);

    // also check the NamesDisplayMode button itself would be disabled when
    // coordinatorMode != 'none'.
    await tester.pumpWidget(MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: () {
          // this should not actually get wired up below
        },
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'main',
      ),
    ));
    await tester.pumpAndSettle();

    ElevatedButton showButton =
        tester.widget(find.widgetWithText(ElevatedButton, 'Show Coord(s)'));
    expect(showButton.onPressed, isNull);

    // when coordinatorMode == 'none' the callback should be present
    bool called = false;
    await tester.pumpWidget(MaterialApp(
      home: NamesDisplayMode(
        onShowSplits: null,
        onImplSplit: null,
        onShowCoords: () {
          called = true;
        },
        onSetC: null,
        onSetCC: null,
        coordinatorMode: 'none',
      ),
    ));
    await tester.pumpAndSettle();
    showButton =
        tester.widget(find.widgetWithText(ElevatedButton, 'Show Coord(s)'));
    expect(showButton.onPressed, isNotNull);
    // verify that tapping actually invokes the callback
    await tester.tap(find.widgetWithText(ElevatedButton, 'Show Coord(s)'));
    await tester.pumpAndSettle();
    expect(called, isTrue);
  });
}
