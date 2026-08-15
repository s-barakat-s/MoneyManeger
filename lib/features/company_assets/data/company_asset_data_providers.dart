import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business/application/business_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/repositories/company_asset_repository.dart';
import 'repositories/firestore_company_asset_repository.dart';

final firestoreCompanyAssetRepositoryProvider =
    Provider<CompanyAssetRepository>((ref) {
      return FirestoreCompanyAssetRepository(
        scope: ref.watch(currentDataScopeProvider),
        actingUid: ref.watch(authenticatedActorUidProvider),
      );
    });
