import '../../../../shared/models/company_asset.dart';
import '../../domain/repositories/company_asset_repository.dart';

class UpdateAsset {
  const UpdateAsset(this._repository);

  final CompanyAssetRepository _repository;

  Future<void> call(CompanyAsset asset) {
    return _repository.updateAsset(asset);
  }
}
