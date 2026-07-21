// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanyAsset _$CompanyAssetFromJson(Map<String, dynamic> json) =>
    _CompanyAsset(
      id: json['id'] as String,
      name: json['name'] as String,
      category: $enumDecode(_$AssetCategoryEnumMap, json['category']),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CompanyAssetToJson(_CompanyAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$AssetCategoryEnumMap[instance.category]!,
      'purchasePrice': instance.purchasePrice,
      'purchaseDate': instance.purchaseDate.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'note': instance.note,
    };

const _$AssetCategoryEnumMap = {
  AssetCategory.equipment: 'equipment',
  AssetCategory.electronics: 'electronics',
  AssetCategory.furniture: 'furniture',
  AssetCategory.vehicle: 'vehicle',
  AssetCategory.office: 'office',
  AssetCategory.other: 'other',
};
