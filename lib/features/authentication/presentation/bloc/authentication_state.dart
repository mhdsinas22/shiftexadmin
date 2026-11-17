enum AuthenticationStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthenticationState {
  final AuthenticationStatus status;
  final String errorMessage;

  AuthenticationState({
    this.status = AuthenticationStatus.initial,
    this.errorMessage = '',
  });

  AuthenticationState copyWith({
    AuthenticationStatus? status,
    String? errorMessage,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
