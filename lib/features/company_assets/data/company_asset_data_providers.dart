import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../domain/repositories/company_asset_repository.dart';
import 'repositories/firestore_company_asset_repository.dart';

final firestoreCompanyAssetRepositoryProvider =
    Provider<CompanyAssetRepository>((ref) {
      return FirestoreCompanyAssetRepository(
        firestore: ref.watch(firebaseFirestoreProvider),
        auth: ref.watch(firebaseAuthProvider),
      );
    });
