/// Base Result pattern using Dart 3 sealed classes.
/// Allows returning either [Success] or [FailureResult] without external dependencies.
sealed class Result<S, F> {
  const Result();

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is FailureResult<S, F>;

  S? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    FailureResult() => null,
  };

  F? get failureOrNull => switch (this) {
    Success() => null,
    FailureResult(failure: final f) => f,
  };

  R fold<R>({
    required R Function(S data) onSuccess,
    required R Function(F failure) onFailure,
  }) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      FailureResult(failure: final f) => onFailure(f),
    };
  }
}

final class Success<S, F> extends Result<S, F> {
  final S data;
  const Success(this.data);
}

final class FailureResult<S, F> extends Result<S, F> {
  final F failure;
  const FailureResult(this.failure);
}
