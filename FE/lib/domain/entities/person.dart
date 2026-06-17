import 'package:flutter/material.dart';

/// A team member. Avatars are deterministic initials on a brand color, so no
/// profile image is required.
@immutable
class Person {
  final String id;
  final String name;
  final String? email;

  /// First grapheme of the name, used for the initials avatar.
  final String initial;

  /// Deterministic avatar color.
  final Color color;

  const Person({
    required this.id,
    required this.name,
    required this.initial,
    required this.color,
    this.email,
  });

  /// Build a person from a name, deriving the initial and a stable color.
  factory Person.fromName({
    required String id,
    required String name,
    String? email,
  }) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;
    return Person(
      id: id,
      name: trimmed.isEmpty ? '익명' : trimmed,
      initial: initial,
      color: _colorFor(id.isNotEmpty ? id : trimmed),
      email: email,
    );
  }

  static const _palette = [
    Color(0xFF2F6F8F),
    Color(0xFFB06A2C),
    Color(0xFF5B6B3A),
    Color(0xFF8A4A5C),
    Color(0xFF3A5B6B),
    Color(0xFF6D5BA6),
    Color(0xFF2F9E6F),
  ];

  static Color _colorFor(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _palette[h % _palette.length];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initial': initial,
        'color': color.toARGB32(),
        if (email != null) 'email': email,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        initial: json['initial'] as String,
        color: Color(json['color'] as int),
        email: json['email'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Person && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
