/// A failure surfaced from the data/service layers, carrying a user-facing
/// (Korean) message and an optional cause for logging.
class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  /// Network / server reachability problems.
  const AppException.network([this.cause]) : message = '네트워크 연결을 확인해 주세요.';

  /// The requested resource was not found.
  const AppException.notFound([this.cause]) : message = '요청한 항목을 찾을 수 없어요.';

  /// Local storage read/write problems.
  const AppException.storage([this.cause]) : message = '저장된 데이터를 불러오지 못했어요.';

  @override
  String toString() => 'AppException($message${cause != null ? ', $cause' : ''})';
}
