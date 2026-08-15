import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/auth/actor_identity.dart';
import 'package:money_manager/core/data/firestore_audit_metadata.dart';
import 'package:money_manager/features/auth/application/auth_providers.dart';
import 'package:money_manager/shared/models/debt_payment.dart';
import 'package:money_manager/shared/models/transaction.dart' as money;

void main() {
  test('create metadata contains creator, updater, and server timestamps', () {
    final metadata = FirestoreAuditMetadata.forCreate('user-a');

    expect(metadata['createdBy'], 'user-a');
    expect(metadata['updatedBy'], 'user-a');
    expect(metadata['createdAt'], isA<FieldValue>());
    expect(metadata['updatedAt'], isA<FieldValue>());
  });

  test('update metadata changes updater without replacing creator fields', () {
    final original = FirestoreAuditMetadata.forCreate('user-a');
    final updated = {
      ...original,
      ...FirestoreAuditMetadata.forUpdate('user-b'),
    };

    expect(updated['createdBy'], 'user-a');
    expect(identical(updated['createdAt'], original['createdAt']), isTrue);
    expect(updated['updatedBy'], 'user-b');
    expect(updated['updatedAt'], isA<FieldValue>());
  });

  test('authenticated dependency changes actor when the account changes', () {
    final container = ProviderContainer(
      overrides: [currentUidProvider.overrideWithValue('user-a')],
    );
    addTearDown(container.dispose);

    expect(container.read(authenticatedActorUidProvider), 'user-a');

    container.updateOverrides([currentUidProvider.overrideWithValue('user-b')]);
    expect(container.read(authenticatedActorUidProvider), 'user-b');
  });

  test('missing authenticated actor is rejected', () {
    expect(
      () => FirestoreAuditMetadata.forCreate(' '),
      throwsA(isA<MissingAuthenticatedActorException>()),
    );
  });

  test('business scope identifier is not used as actor identity', () {
    const businessId = 'business-a';
    const authenticatedUid = 'user-a';

    final metadata = FirestoreAuditMetadata.forCreate(authenticatedUid);

    expect(metadata['createdBy'], authenticatedUid);
    expect(metadata['createdBy'], isNot(businessId));
  });

  test('models tolerate records created before audit metadata existed', () {
    final transaction = money.Transaction(
      id: 'transaction-a',
      ownerId: 'owner-a',
      type: money.TransactionType.income,
      amount: 10,
      date: DateTime(2026),
    );
    final payment = DebtPayment(
      id: 'payment-a',
      debtId: 'debt-a',
      amount: 5,
      date: DateTime(2026),
    );

    expect(transaction.audit.createdBy, isNull);
    expect(transaction.audit.updatedBy, isNull);
    expect(payment.audit.createdBy, isNull);
    expect(payment.audit.updatedAt, isNull);
  });

  test('archive metadata attributes archive and update to the same actor', () {
    final metadata = FirestoreAuditMetadata.forArchive('user-c');

    expect(metadata['archivedBy'], 'user-c');
    expect(metadata['updatedBy'], 'user-c');
    expect(metadata['archivedAt'], isA<FieldValue>());
    expect(metadata['updatedAt'], isA<FieldValue>());
  });
}
