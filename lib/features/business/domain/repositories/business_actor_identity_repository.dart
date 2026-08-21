abstract interface class BusinessActorIdentityRepository {
  Future<Map<String, String>> resolveActorNames({
    required String businessId,
    required Iterable<String> actorUids,
  });

  Future<Map<String, String>> resolveTransactionActors({
    required String businessId,
    required Iterable<String> transactionIds,
  });
}
