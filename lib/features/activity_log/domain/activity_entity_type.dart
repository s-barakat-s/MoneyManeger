enum ActivityEntityType {
  owner('owner'),
  transaction('transaction'),
  transfer('transfer'),
  debt('debt'),
  receivable('receivable'),
  payment('payment'),
  asset('asset'),
  member('member'),
  invitation('invitation'),
  business('business');

  const ActivityEntityType(this.persistedValue);

  final String persistedValue;

  static ActivityEntityType? tryParse(Object? value) {
    if (value is! String) return null;
    for (final type in ActivityEntityType.values) {
      if (type.persistedValue == value) return type;
    }
    return null;
  }
}
