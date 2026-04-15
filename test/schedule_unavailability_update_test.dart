import 'package:flutter_test/flutter_test.dart';
import 'package:omnilore_scheduler/model/change.dart';
import 'package:omnilore_scheduler/scheduling.dart';

void main() {
  test('Select-only flow updates scheduled slot state', () async {
    final scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    final course = scheduling.getCourseCodes().first;
    const time = 0;

    final beforeTime = scheduling.scheduleControl.scheduledTimeFor(course);
    expect(beforeTime, -1);

    scheduling.scheduleControl.schedule(course, time);

    expect(scheduling.scheduleControl.scheduledTimeFor(course), time);
    expect(
      scheduling.scheduleControl.getNbrUnavailable(course, time),
      scheduling.overviewData.getNbrDropTime(course),
    );
  });

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

  test('Backup bad-time drops still count as backup additions', () async {
    final scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    final courses = scheduling.getCourseCodes().toList(growable: false);
    String? chosenCourse;
    String? chosenPerson;

    for (final course in courses) {
      for (var time = 0; time < 20 && chosenCourse == null; time++) {
        scheduling.scheduleControl.schedule(course, time);

        final dropTime = scheduling.overviewData.getPeopleDropTime(course);
        final backupPeople = <String>{};
        for (var rank = 1; rank <= 5; rank++) {
          backupPeople
              .addAll(scheduling.overviewData.getPeopleForClassRank(course, rank));
        }

        final overlap = dropTime.intersection(backupPeople);
        if (overlap.isNotEmpty) {
          chosenCourse = course;
          chosenPerson = overlap.first;
        }
      }
      if (chosenCourse != null) {
        break;
      }
    }

    expect(chosenCourse, isNotNull,
        reason:
            'Expected at least one backup-listed person to be dropped for bad time.');
    expect(chosenPerson, isNotNull);

    expect(scheduling.overviewData.getPeopleDropTime(chosenCourse!),
        contains(chosenPerson));
    expect(scheduling.overviewData.getPeopleAddFromBackup(chosenCourse),
        contains(chosenPerson));
    expect(scheduling.overviewData.getPeopleForResultingClass(chosenCourse),
      isNot(contains(chosenPerson)));
  });

  test('Deselecting a timeslot restores unavailability counts', () async {
    final scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    final peopleByName = {
      for (final person in scheduling.getPeople()) person.getName(): person,
    };

    final courses = scheduling.getCourseCodes().toList(growable: false);
    String? targetCourse;
    int targetTime = -1;

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
      if (targetCourse != null) {
        break;
      }
    }

    expect(targetCourse, isNotNull,
        reason: 'Expected at least one course with a resulting class.');
    expect(bestUnavailable, greaterThan(0));

    final beforeCounts = List<int>.generate(
      20,
      (time) => scheduling.scheduleControl.getNbrUnavailable(targetCourse!, time),
        growable: false);

    scheduling.scheduleControl.schedule(targetCourse!, targetTime);
    scheduling.scheduleControl.unschedule(targetCourse, targetTime);
    scheduling.compute(Change.schedule);

    final afterCounts = List<int>.generate(
      20,
      (time) => scheduling.scheduleControl.getNbrUnavailable(targetCourse!, time),
        growable: false);

    expect(afterCounts, equals(beforeCounts));
  });

  test('Visible drop categories come from first-choice or backup-added sets',
      () async {
    final scheduling = Scheduling();
    await scheduling.loadCourses('test/resources/course.txt');
    await scheduling.loadPeople('test/resources/people.txt');

    // Force scheduling so drop categories are populated.
    final courses = scheduling.getCourseCodes().toList(growable: false);
    for (var i = 0; i < courses.length; i++) {
      scheduling.scheduleControl.schedule(courses[i], i % 20);
    }

    for (final course in courses) {
      final firstChoice = scheduling.overviewData.getPeopleForClassRank(course, 0);
      final addFromBackup = scheduling.overviewData.getPeopleAddFromBackup(course);
      final eligible = firstChoice.union(addFromBackup);

      final dropTime = scheduling.overviewData.getPeopleDropTime(course);
      final dropDup = scheduling.overviewData.getPeopleDropDup(course);
      final dropFull = scheduling.overviewData.getPeopleDropFull(course);

      expect(eligible.containsAll(dropTime), isTrue,
          reason: 'Drop bad-time should be from first-choice or backup-added');
      expect(eligible.containsAll(dropDup), isTrue,
          reason: 'Drop dup should be from first-choice or backup-added');
      expect(eligible.containsAll(dropFull), isTrue,
          reason: 'Drop full should be from first-choice or backup-added');
    }
  });

}
