import '../../../shared/models/company_asset.dart';

extension AssetCategoryLabel on AssetCategory {
  String get label {
    return switch (this) {
      AssetCategory.equipment => 'Equipment',
      AssetCategory.electronics => 'Electronics',
      AssetCategory.furniture => 'Furniture',
      AssetCategory.vehicle => 'Vehicle',
      AssetCategory.office => 'Office',
      AssetCategory.other => 'Other',
    };
  }
}
