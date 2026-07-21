import '../../../../shared/models/company_asset.dart';
import '../../domain/repositories/company_asset_repository.dart';

class WatchAssets {
  const WatchAssets(this._repository);

  final CompanyAssetRepository _repository;

  Stream<List<CompanyAsset>> call() {
    return _repository.watchAssets();
  }
}
