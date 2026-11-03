/// A message the auth flows may show to the user.
///
/// Data sources throw it for expected rejections so use cases can turn the
/// failure into form state without leaking transport exceptions.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
