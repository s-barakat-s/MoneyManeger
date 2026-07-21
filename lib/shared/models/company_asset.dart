import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_asset.freezed.dart';
part 'company_asset.g.dart';

enum AssetCategory {
  equipment,
  electronics,
  furniture,
  vehicle,
  office,
  other,
}

@freezed
abstract class CompanyAsset with _$CompanyAsset {
  const factory CompanyAsset({
    required String id,
    required String name,
    required AssetCategory category,
    required double purchasePrice,
    required DateTime purchaseDate,
    required DateTime createdAt,
    String? note,
  }) = _CompanyAsset;

  factory CompanyAsset.fromJson(Map<String, dynamic> json) =>
      _$CompanyAssetFromJson(json);
}
