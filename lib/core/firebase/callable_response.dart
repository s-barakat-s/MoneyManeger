Map<String, dynamic> callableMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('The server returned an invalid response.');
}

List<Map<String, dynamic>> callableMapList(Object? value) {
  if (value is! List) {
    throw const FormatException('The server returned an invalid list.');
  }
  return value.map(callableMap).toList(growable: false);
}

String requiredResponseString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('The server response is missing $key.');
}

String? optionalResponseString(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
