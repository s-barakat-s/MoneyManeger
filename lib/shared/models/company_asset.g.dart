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
      note: json['note'] as String?,
      audit: json['audit'] == null
          ? const AuditMetadata()
          : AuditMetadata.fromJson(json['audit'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CompanyAssetToJson(_CompanyAsset instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$AssetCategoryEnumMap[instance.category]!,
      'purchasePrice': instance.purchasePrice,
      'purchaseDate': instance.purchaseDate.toIso8601String(),
      'note': instance.note,
      'audit': instance.audit,
    };

const _$AssetCategoryEnumMap = {
  AssetCategory.equipment: 'equipment',
  AssetCategory.electronics: 'electronics',
  AssetCategory.furniture: 'furniture',
  AssetCategory.vehicle: 'vehicle',
  AssetCategory.office: 'office',
  AssetCategory.other: 'other',
};
