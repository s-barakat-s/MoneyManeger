import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/firebase/firebase_providers.dart';
import 'features/company_assets/application/company_asset_providers.dart';
import 'features/company_assets/data/company_asset_data_providers.dart';
import 'features/debts/application/debt_providers.dart';
import 'features/debts/data/debt_data_providers.dart';
import 'features/owners/application/owner_providers.dart';
import 'features/owners/data/owner_data_providers.dart';
import 'features/transactions/application/transaction_providers.dart';
import 'features/transactions/data/transaction_data_providers.dart';
import 'features/transfers/application/transfer_providers.dart';
import 'features/transfers/data/transfer_data_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseApp = await initializeFirebaseApp();
  configureCloudFirestore(firebaseApp);

  runApp(
    ProviderScope(
      overrides: [
        firebaseAppProvider.overrideWithValue(firebaseApp),
        ownerRepositoryProvider.overrideWith((ref) {
          return ref.watch(firestoreOwnerRepositoryProvider);
        }),
        transactionRepositoryProvider.overrideWith((ref) {
          return ref.watch(firestoreTransactionRepositoryProvider);
        }),
        transferRepositoryProvider.overrideWith((ref) {
          return ref.watch(firestoreTransferRepositoryProvider);
        }),
        debtRepositoryProvider.overrideWith((ref) {
          return ref.watch(firestoreDebtRepositoryProvider);
        }),
        companyAssetRepositoryProvider.overrideWith((ref) {
          return ref.watch(firestoreCompanyAssetRepositoryProvider);
        }),
      ],
      child: const MoneyManagerApp(),
    ),
  );
}
