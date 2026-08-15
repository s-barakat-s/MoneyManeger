String requireAuthenticatedActorUid(String? uid) {
  final value = uid?.trim();
  if (value == null || value.isEmpty) {
    throw const MissingAuthenticatedActorException();
  }
  return value;
}

class MissingAuthenticatedActorException implements Exception {
  const MissingAuthenticatedActorException();
}
