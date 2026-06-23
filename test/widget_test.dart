import 'package:flutter_test/flutter_test.dart';

import 'package:skydogs/data/models/sleep_schedule.dart';

void main() {
  test('SleepSchedule defaults expose the bedtime label', () {
    final schedule = SleepSchedule.defaults();

    expect(schedule.bedtimeLabel, '22:45');
    expect(schedule.timerMinutes, 45);
  });
}
