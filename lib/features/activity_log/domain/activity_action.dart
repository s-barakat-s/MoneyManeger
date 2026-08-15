enum ActivityAction {
  ownerCreated('owner.created'),
  ownerUpdated('owner.updated'),
  ownerArchived('owner.archived'),
  transactionCreated('transaction.created'),
  transactionUpdated('transaction.updated'),
  transactionArchived('transaction.archived'),
  transferCreated('transfer.created'),
  transferCorrected('transfer.corrected'),
  transferArchived('transfer.archived'),
  debtCreated('debt.created'),
  debtUpdated('debt.updated'),
  debtArchived('debt.archived'),
  debtRestored('debt.restored'),
  receivableCreated('receivable.created'),
  receivableUpdated('receivable.updated'),
  receivableArchived('receivable.archived'),
  receivableRestored('receivable.restored'),
  paymentCreated('payment.created'),
  paymentUpdated('payment.updated'),
  paymentArchived('payment.archived'),
  assetCreated('asset.created'),
  assetUpdated('asset.updated'),
  assetArchived('asset.archived'),
  memberInvited('member.invited'),
  memberRoleChanged('member.roleChanged'),
  memberSuspended('member.suspended'),
  memberReactivated('member.reactivated'),
  memberRemoved('member.removed'),
  memberActivated('member.activated'),
  invitationRevoked('invitation.revoked'),
  businessCreated('business.created');

  const ActivityAction(this.persistedValue);

  final String persistedValue;

  static ActivityAction? tryParse(Object? value) {
    if (value is! String) return null;
    for (final action in ActivityAction.values) {
      if (action.persistedValue == value) return action;
    }
    return null;
  }
}
