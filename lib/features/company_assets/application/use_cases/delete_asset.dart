import '../../domain/repositories/company_asset_repository.dart';

class DeleteAsset {
  const DeleteAsset(this._repository);

  final CompanyAssetRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteAsset(id);
  }
}
