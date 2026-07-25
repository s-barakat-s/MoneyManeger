class SavedAccount {
  const SavedAccount({
    required this.uid,
    required this.email,
    required this.provider,
    required this.lastUsedAt,
    this.username,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final String provider;
  final DateTime lastUsedAt;

  List<String> get providerIds => provider
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  bool get supportsGoogleSignIn => providerIds.contains('google.com');
  bool get supportsPasswordSignIn => providerIds.contains('password');

  SavedAccount copyWith({String? username}) {
    return SavedAccount(
      uid: uid,
      email: email,
      username: username ?? this.username,
      displayName: displayName,
      photoUrl: photoUrl,
      provider: provider,
      lastUsedAt: lastUsedAt,
    );
  }

  String get accountLabel {
    final cleanUsername = username?.trim();
    if (cleanUsername != null && cleanUsername.isNotEmpty) {
      return cleanUsername;
    }
    final cleanDisplayName = displayName?.trim();
    if (cleanDisplayName != null && cleanDisplayName.isNotEmpty) {
      return cleanDisplayName;
    }
    final cleanEmail = email.trim();
    final separator = cleanEmail.indexOf('@');
    if (separator > 0) return cleanEmail.substring(0, separator);
    return 'Account';
  }

  String get accountInitials {
    final parts = accountLabel
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return _firstCharacter(parts.first).toUpperCase();
    return '${_firstCharacter(parts.first)}${_firstCharacter(parts.last)}'
        .toUpperCase();
  }

  factory SavedAccount.fromJson(Map<String, Object?> json) {
    final uid = json['uid'];
    final email = json['email'];
    final provider = json['provider'];
    final lastUsedAt = json['lastUsedAt'];
    if (uid is! String ||
        uid.isEmpty ||
        email is! String ||
        provider is! String ||
        lastUsedAt is! String) {
      throw const FormatException('Invalid saved account');
    }

    return SavedAccount(
      uid: uid,
      email: email,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      provider: provider,
      lastUsedAt: DateTime.parse(lastUsedAt),
    );
  }

  Map<String, Object?> toJson() => {
    'uid': uid,
    'email': email,
    'username': username,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'provider': provider,
    'lastUsedAt': lastUsedAt.toUtc().toIso8601String(),
  };
}

String _firstCharacter(String value) => String.fromCharCode(value.runes.first);
