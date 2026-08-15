import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/data/firestore_paths.dart';

void main() {
  test('resolves profile, business, and membership paths', () {
    expect(FirestorePaths.userProfilePath('user-a'), 'userProfiles/user-a');
    expect(FirestorePaths.businessPath('business-a'), 'businesses/business-a');
    expect(
      FirestorePaths.memberPath('business-a', 'user-a'),
      'businesses/business-a/members/user-a',
    );
  });

  test('resolves every financial collection under the business', () {
    const collections = <String>[
      FirestoreCollections.owners,
      FirestoreCollections.transactions,
      FirestoreCollections.transfers,
      FirestoreCollections.debts,
      FirestoreCollections.receivables,
      FirestoreCollections.payments,
      FirestoreCollections.assets,
    ];

    for (final collection in collections) {
      expect(
        FirestorePaths.businessCollectionPath('business-a', collection),
        'businesses/business-a/$collection',
      );
    }
  });

  test('resolves activity logs under the business', () {
    expect(
      FirestorePaths.businessCollectionPath(
        'business-a',
        FirestoreCollections.activityLogs,
      ),
      'businesses/business-a/activityLogs',
    );
  });

  test('different businesses cannot resolve the same financial path', () {
    expect(
      FirestorePaths.businessCollectionPath(
        'business-a',
        FirestoreCollections.transactions,
      ),
      isNot(
        FirestorePaths.businessCollectionPath(
          'business-b',
          FirestoreCollections.transactions,
        ),
      ),
    );
  });
}
