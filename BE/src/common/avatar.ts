/**
 * Deterministic avatar identity, ported 1:1 from the Flutter client
 * (`FE/lib/domain/entities/person.dart`) so a server-issued Person renders the
 * same initial + color the app would have produced locally.
 */

// The exact warm palette from Person._palette, as 0xAARRGGBB ints.
const PALETTE = [
  0xff2f6f8f, 0xffb06a2c, 0xff5b6b3a, 0xff8a4a5c, 0xff3a5b6b, 0xff6d5ba6,
  0xff2f9e6f,
];

/**
 * Pick a stable color for a seed string. Mirrors Person._colorFor: a rolling
 * `h = h * 31 + codeUnit` hash (UTF-16 code units, same as Dart's), masked to
 * 31 bits, indexed into the palette. Returns an 0xAARRGGBB int — the same shape
 * `Color.toARGB32()` serializes and `Person.fromJson` reads back.
 */
export function avatarColor(seed: string): number {
  let h = 0;
  for (let i = 0; i < seed.length; i++) {
    h = (h * 31 + seed.charCodeAt(i)) & 0x7fffffff;
  }
  return PALETTE[h % PALETTE.length];
}

/** First grapheme of a name for the initials avatar (Person.fromName). */
export function initialOf(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return '?';
  return Array.from(trimmed)[0];
}
