import '../../../../shared/models/company_asset.dart';

abstract interface class CompanyAssetRepository {
  Stream<List<CompanyAsset>> watchAssets();

  Future<void> createAsset(CompanyAsset asset);

  Future<void> updateAsset(CompanyAsset asset);

  Future<void> deleteAsset(String id);
}
