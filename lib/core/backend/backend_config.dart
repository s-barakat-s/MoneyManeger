abstract final class BackendConfig {
  static const baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://moneymaneger.1sbarakats.deno.net',
  );

  static Uri endpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
