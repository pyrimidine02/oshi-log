/// EN: Native social login service wrapping Google Sign-In and Sign in with Apple SDKs.
/// KO: Google Sign-In과 Sign in with Apple SDK를 래핑하는 네이티브 소셜 로그인 서비스.
library;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/utils/result.dart';

// EN: Web (server) OAuth 2.0 client ID for Android Google Sign-In.
//     On iOS the client ID is read from GoogleService-Info.plist automatically.
//     Set via --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.
// KO: Android Google 로그인용 웹(서버) OAuth 2.0 클라이언트 ID.
//     iOS는 GoogleService-Info.plist에서 자동으로 읽습니다.
//     --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id> 로 주입하세요.
const String _googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '413403814343-8dumqdu0qn0jlo7qqgvh0312215687t9.apps.googleusercontent.com',
);

/// EN: Credentials returned by Sign in with Apple.
/// KO: Sign in with Apple이 반환하는 자격증명.
class AppleSignInCredentials {
  const AppleSignInCredentials({
    required this.identityToken,
    this.email,
    this.fullName,
  });

  /// EN: Apple identity token (JWT) to send to the backend.
  /// KO: 백엔드로 전송할 Apple identity 토큰 (JWT).
  final String identityToken;

  /// EN: Cached email — may be null if Apple did not provide it and cache is empty.
  /// KO: 캐시된 이메일 — Apple이 미제공이고 캐시도 없는 경우 null.
  final String? email;

  /// EN: Cached full name — may be null if Apple did not provide it and cache is empty.
  /// KO: 캐시된 전체 이름 — Apple이 미제공이고 캐시도 없는 경우 null.
  final String? fullName;
}

/// EN: Service for triggering native Google/Apple sign-in flows.
///     Handles Apple credential caching so the backend always receives
///     email/fullName even after the first sign-in.
/// KO: 네이티브 Google/Apple 로그인 플로우를 실행하는 서비스.
///     Apple 자격증명 캐시를 관리하여 최초 로그인 이후에도
///     백엔드가 항상 email/fullName을 받을 수 있도록 합니다.
class NativeSocialLoginService {
  NativeSocialLoginService({
    required SecureStorage secureStorage,
    GoogleSignIn? googleSignIn,
  }) : _secureStorage = secureStorage,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: ['email'],
             serverClientId: _googleServerClientId.isNotEmpty
                 ? _googleServerClientId
                 : null,
           );

  final SecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  /// EN: Launch Google Sign-In and return the Google ID token.
  ///     Returns [UserCancelledFailure] if the user dismisses the sign-in sheet.
  /// KO: Google 로그인을 실행하고 Google ID 토큰을 반환합니다.
  ///     사용자가 로그인 시트를 닫으면 [UserCancelledFailure]를 반환합니다.
  Future<Result<String>> signInWithGoogle() async {
    try {
      // EN: Sign out first to force account picker on every tap.
      // KO: 매번 계정 선택기를 표시하기 위해 먼저 로그아웃합니다.
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // EN: User cancelled the sign-in flow.
        // KO: 사용자가 로그인 플로우를 취소했습니다.
        return Result.failure(
          const AuthFailure(
            'Google sign-in cancelled by user',
            code: 'sign_in_cancelled',
          ),
        );
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return Result.failure(
          const AuthFailure(
            'Google idToken unavailable',
            code: 'google_id_token_missing',
          ),
        );
      }

      return Result.success(idToken);
    } on Exception catch (e) {
      return Result.failure(
        AuthFailure('Google sign-in error: $e', code: 'google_sign_in_error'),
      );
    }
  }

  /// EN: Launch Sign in with Apple and return credentials (with email/fullName
  ///     read from Keychain cache when Apple does not provide them).
  ///     Returns [UserCancelledFailure] if the user cancels.
  /// KO: Apple 로그인을 실행하고 자격증명을 반환합니다.
  ///     Apple이 email/fullName을 제공하지 않으면 Keychain 캐시에서 읽습니다.
  ///     사용자가 취소하면 [UserCancelledFailure]를 반환합니다.
  Future<Result<AppleSignInCredentials>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        return Result.failure(
          const AuthFailure(
            'Apple identityToken unavailable',
            code: 'apple_identity_token_missing',
          ),
        );
      }

      // EN: Persist email/fullName when Apple provides them (first sign-in only).
      // KO: Apple이 제공하는 경우(최초 로그인)에만 email/fullName을 저장합니다.
      final appleEmail = credential.email;
      final appleFullName = _buildFullName(
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      await _secureStorage.saveAppleCredentials(
        email: appleEmail,
        fullName: appleFullName,
      );

      // EN: Load from cache — includes the value just saved (if any).
      // KO: 캐시에서 로드합니다 — 방금 저장된 값도 포함됩니다 (있는 경우).
      final cachedEmail = await _secureStorage.getAppleEmail();
      final cachedFullName = await _secureStorage.getAppleFullName();

      return Result.success(
        AppleSignInCredentials(
          identityToken: identityToken,
          email: cachedEmail,
          fullName: cachedFullName,
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return Result.failure(
          const AuthFailure(
            'Apple sign-in cancelled by user',
            code: 'sign_in_cancelled',
          ),
        );
      }
      return Result.failure(
        AuthFailure(
          'Apple sign-in error: ${e.message}',
          code: 'apple_sign_in_error',
        ),
      );
    } on Exception catch (e) {
      return Result.failure(
        AuthFailure('Apple sign-in error: $e', code: 'apple_sign_in_error'),
      );
    }
  }

  /// EN: Combine given name and family name into a single full-name string.
  /// KO: 이름(given)과 성(family)을 합쳐 전체 이름 문자열을 만듭니다.
  String? _buildFullName({String? givenName, String? familyName}) {
    final parts = [
      if (givenName != null && givenName.isNotEmpty) givenName,
      if (familyName != null && familyName.isNotEmpty) familyName,
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}
