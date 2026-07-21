String formatEgpCurrency(double value) {
  final sign = value < 0 ? '-' : '';
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts.first;
  final decimals = parts.last;
  final buffer = StringBuffer();

  for (var index = 0; index < whole.length; index++) {
    final remaining = whole.length - index;
    buffer.write(whole[index]);

    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return '${sign}EGP $buffer.$decimals';
}
