import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/saved_account.dart';

abstract interface class SavedAccountRepository {
  Future<List<SavedAccount>> load();
  Future<void> upsert(SavedAccount account);
  Future<void> remove(String uid);
  Future<void> clear();
}

class SharedPreferencesSavedAccountRepository
    implements SavedAccountRepository {
  const SharedPreferencesSavedAccountRepository();

  static const _accountsKey = 'saved_google_accounts_v1';
  static const _legacyCurrentUidKey = 'saved_google_accounts_current_uid_v1';

  @override
  Future<List<SavedAccount>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_accountsKey);
    if (encoded == null) return const [];

    try {
      final values = jsonDecode(encoded);
      if (values is! List) return const [];
      final accounts = <SavedAccount>[];
      for (final value in values) {
        try {
          if (value is Map) {
            accounts.add(
              SavedAccount.fromJson(Map<String, Object?>.from(value)),
            );
          }
        } on Object {
          // Ignore only the corrupt record and retain other valid accounts.
        }
      }
      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return accounts;
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> upsert(SavedAccount account) async {
    final accounts = await load();
    final updated = [
      account,
      ...accounts.where((saved) => saved.uid != account.uid),
    ];
    await _write(updated);
  }

  @override
  Future<void> remove(String uid) async {
    final accounts = await load();
    await _write(accounts.where((account) => account.uid != uid).toList());
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accountsKey);
    await preferences.remove(_legacyCurrentUidKey);
  }

  Future<void> _write(List<SavedAccount> accounts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _accountsKey,
      jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }
}
