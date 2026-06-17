import 'package:flutter/material.dart';
import '../domain/entities/person.dart';

/// The signed-in user. In production this is populated from an auth provider;
/// local-first, it's a fixed on-device profile. Centralizing it here means the
/// rest of the app never hard-codes "me".
class Session {
  final Person currentUser;

  const Session({required this.currentUser});

  /// The default local profile used when there is no auth backend.
  factory Session.local() => const Session(
        currentUser: Person(
          id: 'u-me',
          name: '준호',
          initial: '준',
          color: Color(0xFF1A1714),
        ),
      );
}
