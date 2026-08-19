String formatReadableDate(DateTime value, {DateTime? relativeTo}) {
  final now = relativeTo ?? DateTime.now();
  final date = DateTime(value.year, value.month, value.day);
  final today = DateTime(now.year, now.month, now.day);

  if (date == today) return 'Today';
  if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';

  return '${_months[value.month - 1]} ${value.day}, ${value.year}';
}

String formatReadableDateTime(DateTime value, {DateTime? relativeTo}) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '${formatReadableDate(value, relativeTo: relativeTo)} at '
      '$hour:$minute $period';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
