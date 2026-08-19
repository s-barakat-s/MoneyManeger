import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/utils/readable_date_formatter.dart';

void main() {
  final now = DateTime(2026, 8, 19, 14, 30);

  test('formats relative and calendar dates consistently', () {
    expect(formatReadableDate(DateTime(2026, 8, 19), relativeTo: now), 'Today');
    expect(
      formatReadableDate(DateTime(2026, 8, 18), relativeTo: now),
      'Yesterday',
    );
    expect(
      formatReadableDate(DateTime(2026, 7, 4), relativeTo: now),
      'Jul 4, 2026',
    );
  });

  test('formats readable time without changing the source value', () {
    expect(
      formatReadableDateTime(DateTime(2026, 8, 19, 14, 5), relativeTo: now),
      'Today at 2:05 PM',
    );
  });
}
