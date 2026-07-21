import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/company_asset.dart';
import '../domain/repositories/company_asset_repository.dart';
import 'use_cases/create_asset.dart';
import 'use_cases/delete_asset.dart';
import 'use_cases/update_asset.dart';
import 'use_cases/watch_assets.dart';

final companyAssetRepositoryProvider = Provider<CompanyAssetRepository>((ref) {
  throw UnimplementedError('CompanyAssetRepository is not configured.');
});

final watchAssetsProvider = Provider<WatchAssets>((ref) {
  return WatchAssets(ref.watch(companyAssetRepositoryProvider));
});

final createAssetProvider = Provider<CreateAsset>((ref) {
  return CreateAsset(ref.watch(companyAssetRepositoryProvider));
});

final updateAssetProvider = Provider<UpdateAsset>((ref) {
  return UpdateAsset(ref.watch(companyAssetRepositoryProvider));
});

final deleteAssetProvider = Provider<DeleteAsset>((ref) {
  return DeleteAsset(ref.watch(companyAssetRepositoryProvider));
});

final assetsStreamProvider = StreamProvider.autoDispose<List<CompanyAsset>>((
  ref,
) {
  return ref.watch(watchAssetsProvider)();
});

final totalAssetsValueProvider = Provider.autoDispose<AsyncValue<double>>((ref) {
  final assets = ref.watch(assetsStreamProvider);

  return assets.whenData(
    (value) => value.fold(0, (total, asset) => total + asset.purchasePrice),
  );
});
