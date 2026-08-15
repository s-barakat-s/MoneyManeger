class Business {
  const Business({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.schemaVersion,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final int schemaVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
