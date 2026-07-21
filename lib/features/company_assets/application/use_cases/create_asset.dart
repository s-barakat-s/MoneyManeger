import '../../../../shared/models/company_asset.dart';
import '../../domain/repositories/company_asset_repository.dart';

class CreateAsset {
  const CreateAsset(this._repository);

  final CompanyAssetRepository _repository;

  Future<void> call(CompanyAsset asset) {
    return _repository.createAsset(asset);
  }
}
