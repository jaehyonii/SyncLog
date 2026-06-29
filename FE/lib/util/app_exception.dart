/// A failure surfaced from the data/service layers, carrying a user-facing
/// (Korean) message and an optional cause for logging.
class AppException implements Exception {
  final String message;
  final Object? cause;

  /// HTTP status when the failure came back from the server (null for local /
  /// network-reachability errors). Lets callers tell a server rejection (e.g. a
  /// 403/409 business-rule error) apart from being offline.
  final int? status;

  const AppException(this.message, [this.cause]) : status = null;

  /// A failure the server responded with, preserving its status + message.
  const AppException.server(this.status, this.message, [this.cause]);

  /// Network / server reachability problems.
  const AppException.network([this.cause])
      : message = '네트워크 연결을 확인해 주세요.',
        status = null;

  /// The requested resource was not found.
  const AppException.notFound([this.cause])
      : message = '요청한 항목을 찾을 수 없어요.',
        status = 404;

  /// Local storage read/write problems.
  const AppException.storage([this.cause])
      : message = '저장된 데이터를 불러오지 못했어요.',
        status = null;

  /// True when the server responded with an error (vs. an offline/local fault).
  bool get isFromServer => status != null;

  @override
  String toString() => 'AppException($message${cause != null ? ', $cause' : ''})';
}
