import 'person.dart';

/// A locally-registered account. In local-first mode this is the credential
/// record SyncLog stores on-device; the user-facing identity ([Person]) is
/// derived from it. `passwordHash` is a non-reversible digest — never the raw
/// password (see [AuthController] for the hashing). When a real backend lands,
/// this whole record is replaced by a server-issued session token.
class Account {
  final String id;
  final String name;
  final String email;
  final String passwordHash;

  const Account({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  /// The user-facing identity used everywhere in the app (avatar, attribution).
  Person toPerson() => Person.fromName(id: id, name: name, email: email);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
      );
}
