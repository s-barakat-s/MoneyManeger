import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/company_asset_repository.dart';
import 'repositories/firestore_company_asset_repository.dart';

final firestoreCompanyAssetRepositoryProvider =
    Provider<CompanyAssetRepository>((ref) {
      final uid = ref.watch(currentUidProvider);
      if (uid == null) {
        throw StateError('Asset repository requires an authenticated user.');
      }
      return FirestoreCompanyAssetRepository(
        firestore: ref.watch(firebaseFirestoreProvider),
        uid: uid,
      );
    });
