import 'package:flutter/widgets.dart';

/// A tiny loading/data/error union for driving comprehensive UI states without
/// pulling in a heavier state-management dependency.
sealed class AsyncValue<T> {
  const AsyncValue();

  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T value) = AsyncData<T>;
  const factory AsyncValue.error(Object error, [String? message]) = AsyncError<T>;

  /// The current data if available, otherwise null.
  T? get valueOrNull => switch (this) {
        AsyncData<T>(:final value) => value,
        _ => null,
      };

  bool get isLoading => this is AsyncLoading<T>;

  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, String? message) error,
  }) {
    return switch (this) {
      AsyncLoading<T>() => loading(),
      AsyncData<T>(:final value) => data(value),
      final AsyncError<T> e => error(e.error, e.message),
    };
  }
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncValue<T> {
  final T value;
  const AsyncData(this.value);
}

class AsyncError<T> extends AsyncValue<T> {
  final Object error;
  final String? message;
  const AsyncError(this.error, [this.message]);
}

/// Standard loading/error scaffolding so screens render all three states
/// consistently.
extension AsyncValueView<T> on AsyncValue<T> {
  Widget view({
    required Widget Function(T value) data,
    required Widget Function() loading,
    required Widget Function(String message, VoidCallback retry) error,
    required VoidCallback onRetry,
  }) {
    return when(
      loading: loading,
      data: data,
      error: (e, m) => error(m ?? '문제가 발생했어요.', onRetry),
    );
  }
}
