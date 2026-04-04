import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/scheduling.dart';

void main() {
  test('Unavailability matrix updates after scheduling changes', () async {
    final scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    final peopleByName = {
      for (final person in scheduling.getPeople()) person.getName(): person,
    };

    final courses = scheduling.getCourseCodes().toList(growable: false);
    String? targetCourse;
    int targetTime = -1;

    // Pick a course/time pair that maximizes unavailable count among the
    // current resulting class to force roster movement on schedule change.
    var bestUnavailable = -1;
    for (final course in courses) {
      final resulting = scheduling.overviewData.getPeopleForResultingClass(course);
      if (resulting.isEmpty) {
        continue;
      }
      for (var time = 0; time < 20; time++) {
        var unavailableCount = 0;
        for (final name in resulting) {
          if (!peopleByName[name]!.availability[time]) {
            unavailableCount += 1;
          }
        }
        if (unavailableCount > bestUnavailable) {
          bestUnavailable = unavailableCount;
          targetCourse = course;
          targetTime = time;
        }
      }
    }

    expect(targetCourse, isNotNull,
        reason: 'Expected at least one course with a resulting class.');
    expect(bestUnavailable, greaterThan(0),
        reason: 'Expected at least one unavailable person at some time slot.');

    final beforeResulting =
        scheduling.overviewData.getPeopleForResultingClass(targetCourse!).toSet();

    scheduling.scheduleControl.schedule(targetCourse, targetTime);

    final afterResulting =
        scheduling.overviewData.getPeopleForResultingClass(targetCourse).toSet();
    expect(afterResulting, isNot(equals(beforeResulting)),
        reason:
            'Scheduling at a high-conflict time should change resulting roster.');

    final expectedUnavailable = List<int>.filled(20, 0);
    for (final name in afterResulting) {
      final person = peopleByName[name]!;
      for (var time = 0; time < 20; time++) {
        if (!person.availability[time]) {
          expectedUnavailable[time] += 1;
        }
      }
    }

    final dropBadTime = scheduling.overviewData.getNbrDropTime(targetCourse);

    for (var time = 0; time < 20; time++) {
      final expectedForTime =
          (time == targetTime) ? dropBadTime : expectedUnavailable[time];
      expect(
          scheduling.scheduleControl.getNbrUnavailable(targetCourse, time),
          expectedForTime);
    }
  });
}
