/// EN: Supported OAuth providers.
/// KO: 지원하는 OAuth 제공자.
library;

/// EN: OAuth provider identifiers used by the backend.
/// KO: 백엔드에서 사용하는 OAuth 제공자 식별자.
enum OAuthProvider {
  google('google', 'Google'),
  apple('apple', 'Apple'),
  twitter('twitter', 'Twitter');

  const OAuthProvider(this.id, this.displayName);

  final String id;
  final String displayName;

  /// EN: Parse provider from identifier string.
  /// KO: 식별자 문자열에서 제공자 파싱.
  static OAuthProvider? fromId(String id) {
    for (final provider in OAuthProvider.values) {
      if (provider.id == id) return provider;
    }
    return null;
  }
}
