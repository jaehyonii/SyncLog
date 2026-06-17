/// Format seconds as `mm:ss` for timecodes and the recording timer.
String fmtTime(num totalSec) {
  final s = totalSec < 0 ? 0 : totalSec.floor();
  final m = (s ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}

/// Format a millisecond sync offset as a signed seconds string, e.g. `+0.02s`.
String fmtOffset(int offsetMs) {
  final sign = offsetMs > 0 ? '+' : '';
  return '$sign${(offsetMs / 1000).toStringAsFixed(2)}s';
}

/// A warm Korean relative-time label ("방금", "2시간 전", "어제", "3일 전").
String relativeTime(DateTime when, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final d = ref.difference(when);
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays == 1) return '어제';
  if (d.inDays < 7) return '${d.inDays}일 전';
  return '${when.year}.${when.month.toString().padLeft(2, '0')}.${when.day.toString().padLeft(2, '0')}';
}

/// Bump a `vMAJOR.MINOR` tag by one minor version. Falls back to `v1.0`.
String nextVersion(String? latest) {
  if (latest == null) return 'v1.0';
  final m = RegExp(r'^v(\d+)\.(\d+)$').firstMatch(latest.trim());
  if (m == null) return 'v1.0';
  final major = int.parse(m.group(1)!);
  final minor = int.parse(m.group(2)!) + 1;
  return 'v$major.$minor';
}
