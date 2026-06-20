/**
 * Versioning + sync-offset formatting, ported from the Flutter client
 * (`FE/lib/util/time_format.dart`) so commits the server writes carry the same
 * version tags and notes the app would have written locally.
 */
import { randomBytes } from 'node:crypto';

/**
 * A short, human-friendly invite code (8 chars from an unambiguous alphabet —
 * no 0/O/1/I/L). Callers must check uniqueness against existing teams.
 */
export function makeInviteCode(): string {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  const bytes = randomBytes(8);
  let code = '';
  for (let i = 0; i < 8; i++) code += alphabet[bytes[i] % alphabet.length];
  return code;
}

/** Bump a `vMAJOR.MINOR` tag by one minor version. Falls back to `v1.0`. */
export function nextVersion(latest?: string | null): string {
  if (!latest) return 'v1.0';
  const m = /^v(\d+)\.(\d+)$/.exec(latest.trim());
  if (!m) return 'v1.0';
  const major = parseInt(m[1], 10);
  const minor = parseInt(m[2], 10) + 1;
  return `v${major}.${minor}`;
}

/** Format a millisecond sync offset as a signed seconds string, e.g. `+0.02s`. */
export function fmtOffset(offsetMs: number): string {
  const sign = offsetMs > 0 ? '+' : '';
  return `${sign}${(offsetMs / 1000).toFixed(2)}s`;
}

/** The default instrument lineup used to seed a new team's open slots. */
export const INSTRUMENT_LINEUP: ReadonlyArray<{
  part: string;
  partKo: string;
  glyph: string;
}> = [
  { part: 'Drums', partKo: '드럼', glyph: 'drum' },
  { part: 'Bass', partKo: '베이스', glyph: 'audio-lines' },
  { part: 'Guitar', partKo: '기타', glyph: 'guitar' },
  { part: 'Keys', partKo: '건반', glyph: 'piano' },
  { part: 'Vocal', partKo: '보컬', glyph: 'audio-lines' },
  { part: 'Synth', partKo: '신스', glyph: 'piano' },
  { part: 'Perc', partKo: '퍼커션', glyph: 'drum' },
  { part: 'Strings', partKo: '스트링', glyph: 'audio-lines' },
];

/** Cover-color palette for new teams (Team coverColor), as 0xAARRGGBB ints. */
const COVERS = [0xffe6ddcf, 0xffd8d9d2, 0xffdfe2dd, 0xffe3ddd2, 0xffe0dbd0];

export function coverFor(index: number): number {
  return COVERS[index % COVERS.length];
}
