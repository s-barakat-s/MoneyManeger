import '../../../core/backend/authenticated_backend_client.dart';
import '../domain/repositories/business_actor_identity_repository.dart';

class HttpBusinessActorIdentityRepository
    implements BusinessActorIdentityRepository {
  const HttpBusinessActorIdentityRepository({
    required AuthenticatedBackendClient backend,
  }) : _backend = backend;

  static const _batchSize = 100;

  final AuthenticatedBackendClient _backend;

  @override
  Future<Map<String, String>> resolveActorNames({
    required String businessId,
    required Iterable<String> actorUids,
  }) async {
    final uids = actorUids.where((uid) => uid.isNotEmpty).toSet().toList();
    final actors = <String, String>{};
    for (var offset = 0; offset < uids.length; offset += _batchSize) {
      final end = (offset + _batchSize).clamp(0, uids.length).toInt();
      final data = await _backend.post(
        '/api/businesses/${Uri.encodeComponent(businessId)}/actor-names/resolve',
        body: {'actorUids': uids.sublist(offset, end)},
      );
      for (final actor in _mapList(data['actors'])) {
        final uid = _requiredString(actor, 'uid');
        final name = _requiredString(actor, 'name').trim();
        actors[uid] = name.isEmpty ? 'Unknown member' : name;
      }
    }
    return Map.unmodifiable(actors);
  }

  @override
  Future<Map<String, String>> resolveTransactionActors({
    required String businessId,
    required Iterable<String> transactionIds,
  }) async {
    final ids = transactionIds.where((id) => id.isNotEmpty).toSet().toList();
    final actors = <String, String>{};
    for (var offset = 0; offset < ids.length; offset += _batchSize) {
      final candidateEnd = offset + _batchSize;
      final end = candidateEnd < ids.length ? candidateEnd : ids.length;
      final data = await _backend.post(
        '/api/businesses/${Uri.encodeComponent(businessId)}'
        '/transaction-actors/resolve',
        body: {'transactionIds': ids.sublist(offset, end)},
      );
      for (final actor in _mapList(data['actors'])) {
        final uid = _requiredString(actor, 'uid');
        final name = _requiredString(actor, 'name').trim();
        actors[uid] = name.isEmpty ? 'Unknown member' : name;
      }
    }
    return Map.unmodifiable(actors);
  }
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    throw const FormatException('The server returned an invalid actor list.');
  }
  return value
      .map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        throw const FormatException('The server returned an invalid actor.');
      })
      .toList(growable: false);
}

String _requiredString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('The server response is missing $key.');
}
