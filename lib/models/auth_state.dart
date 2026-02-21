/// Represents the authentication state.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String handle;
  final String did;

  const AuthAuthenticated({required this.handle, required this.did});
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
