enum Permission {
  membersRead('members.read'),
  membersManage('members.manage'),
  rolesRead('roles.read'),
  rolesManage('roles.manage'),
  ownersRead('owners.read'),
  ownersCreate('owners.create'),
  ownersUpdate('owners.update'),
  ownersArchive('owners.archive'),
  transactionsRead('transactions.read'),
  transactionsCreate('transactions.create'),
  transactionsUpdate('transactions.update'),
  transactionsArchive('transactions.archive'),
  transfersRead('transfers.read'),
  transfersCreate('transfers.create'),
  transfersCorrect('transfers.correct'),
  transfersArchive('transfers.archive'),
  debtsRead('debts.read'),
  debtsCreate('debts.create'),
  debtsUpdate('debts.update'),
  debtsArchive('debts.archive'),
  receivablesRead('receivables.read'),
  receivablesCreate('receivables.create'),
  receivablesUpdate('receivables.update'),
  receivablesArchive('receivables.archive'),
  assetsRead('assets.read'),
  assetsCreate('assets.create'),
  assetsUpdate('assets.update'),
  assetsArchive('assets.archive'),
  reportsRead('reports.read'),
  activityRead('activity.read'),
  businessSettings('business.settings');

  const Permission(this.persistedValue);

  final String persistedValue;

  static Permission? tryParse(Object? value) {
    if (value is! String) return null;
    for (final permission in Permission.values) {
      if (permission.persistedValue == value) return permission;
    }
    return null;
  }
}
