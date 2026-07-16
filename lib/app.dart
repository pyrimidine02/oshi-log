/// EN: Main application widget with theme and router configuration
/// KO: 테마 및 라우터 구성을 포함한 메인 앱 위젯
library;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/connectivity/connectivity_service.dart';
import 'core/localization/locale_text.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/providers/core_providers.dart';
import 'core/telemetry/telemetry_event_types.dart';
import 'core/telemetry/telemetry_service.dart';
import 'core/notifications/in_app_notification_queue.dart';
import 'core/widgets/overlays/in_app_notification_banner.dart';
import 'core/router/app_router.dart';
import 'core/theme/gbt_colors.dart';
import 'core/theme/gbt_spacing.dart';
import 'core/theme/gbt_typography.dart';
import 'core/theme/gbt_theme.dart';
import 'features/notifications/application/notifications_controller.dart';
import 'features/notifications/domain/entities/notification_entities.dart';
import 'features/notifications/domain/entities/notification_navigation.dart';
import 'features/feed/application/reaction_controller.dart';
import 'features/titles/application/titles_controller.dart';
import 'features/live_events/application/live_events_controller.dart';
import 'features/settings/application/mandatory_consent_controller.dart';
import 'features/settings/application/settings_controller.dart';

String? _lastTrackedScreenPath;

enum _NotificationTapSource { localNotification, remotePush }

/// EN: Main application widget
/// KO: 메인 앱 위젯
class GBTApp extends ConsumerWidget {
  const GBTApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // EN: Keep local notifications initialized once at app scope.
    // KO: 앱 전역에서 로컬 알림 초기화를 1회 유지합니다.
    ref.watch(localNotificationsBootstrapProvider);
    // EN: Keep notification realtime sync alive at app scope.
    // KO: 앱 전역에서 알림 실시간 동기화를 유지합니다.
    ref.watch(notificationsRealtimeBootstrapProvider);
    // EN: Keep remote push registration/tap handling alive at app scope.
    // KO: 앱 전역에서 원격 푸시 등록/탭 처리를 유지합니다.
    ref.watch(remotePushBootstrapProvider);
    // EN: Keep user authorization profile in sync with login/refresh lifecycle.
    // KO: 로그인/토큰 갱신 주기에 맞춰 사용자 권한 프로필을 동기화합니다.
    ref.watch(userAuthorizationBootstrapProvider);
    // EN: Keep post reaction offline outbox sync alive at app scope.
    // KO: 앱 전역에서 게시글 반응 오프라인 대기열 동기화를 유지합니다.
    ref.watch(postReactionOutboxBootstrapProvider);
    // EN: Keep live attendance offline outbox sync alive at app scope.
    // KO: 앱 전역에서 라이브 출석 오프라인 대기열 동기화를 유지합니다.
    ref.watch(liveAttendanceOutboxBootstrapProvider);

    final router = ref.watch(appRouterProvider);
    _trackScreenViewIfNeeded(ref: ref, router: router);
    ref.listen<AsyncValue<LocalNotificationTapEvent>>(
      localNotificationTapEventsProvider,
      (_, next) {
        next.whenData(
          (tapEvent) => _handleLocalNotificationTap(
            ref: ref,
            router: router,
            tapEvent: tapEvent,
            source: _NotificationTapSource.localNotification,
          ),
        );
      },
    );
    ref.listen<AsyncValue<LocalNotificationTapEvent>>(
      remotePushTapEventsProvider,
      (_, next) {
        next.whenData(
          (tapEvent) => _handleLocalNotificationTap(
            ref: ref,
            router: router,
            tapEvent: tapEvent,
            source: _NotificationTapSource.remotePush,
          ),
        );
      },
    );

    // EN: Forward foreground FCM messages to the in-app banner queue.
    // KO: 포그라운드 FCM 메시지를 인앱 배너 큐로 전달합니다.
    ref.listen<AsyncValue<NotificationItem>>(
      remotePushForegroundMessagesProvider,
      (_, next) {
        next.whenData((item) {
          const inAppTypes = {
            notificationTypePostCreated, // POST_CREATED
            'COMMENT_CREATED',
            'COMMENT_REPLY_CREATED',
          };
          final type = normalizeNotificationType(item.type);
          if (inAppTypes.contains(type)) {
            ref
                .read(inAppNotificationQueueProvider.notifier)
                .push(
                  InAppNotificationEntry(
                    id: item.id,
                    title: item.title,
                    body: item.body,
                    type: type,
                    entityId: item.entityId,
                    deeplink: item.deeplink,
                    actionUrl: item.actionUrl,
                    projectCode: item.projectCode,
                  ),
                );
          }
          // EN: Invalidate title caches immediately when a TITLE_EARNED
          //     notification arrives so the title picker always shows
          //     freshly-granted titles without waiting for the next TTL expiry.
          // KO: TITLE_EARNED 알림 수신 즉시 칭호 캐시를 무효화하여 다음 TTL
          //     만료를 기다리지 않고 칭호 피커에서 최신 획득 상태를 표시합니다.
          if (type == notificationTypeTitleEarned) {
            unawaited(
              ref.read(titlesRepositoryProvider.future).then((repo) async {
                await repo.invalidateTitleCaches();
                unawaited(ref.read(activeTitleProvider.notifier).refresh());
              }),
            );
          }
        });
      },
    );

    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Girls Band Tabi',
      debugShowCheckedModeBanner: false,

      // EN: Theme configuration
      // KO: 테마 구성
      theme: GBTTheme.light,
      darkTheme: GBTTheme.dark,
      themeMode: _parseThemeMode(themeMode),

      // EN: Router configuration
      // KO: 라우터 구성
      routerConfig: router,

      // EN: Localization
      // KO: 다국어 지원
      locale: appLocale,
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // EN: Builder for global overlays
      // KO: 전역 오버레이를 위한 빌더
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundGradient = isDark
            ? GBTColors.darkAppBackgroundGradient
            : GBTColors.appBackgroundGradient;
        Intl.defaultLocale = Localizations.localeOf(context).toLanguageTag();
        // EN: Icon brightness flips with theme so status bar & nav bar icons
        //     remain readable in both light and dark mode (edge-to-edge).
        // KO: 테마에 따라 아이콘 밝기를 반전시켜 라이트/다크 모드 모두에서
        //     상태 바·네비게이션 바 아이콘이 잘 보이도록 합니다 (엣지 투 엣지).
        final iconBrightness = isDark ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: iconBrightness,
            systemNavigationBarContrastEnforced: false,
          ),
          // EN: Preserve the platform TextScaler. Individual layouts adapt
          // instead of globally reducing the user's accessibility setting.
          // KO: 운영체제 TextScaler를 그대로 보존합니다. 사용자 접근성 설정을
          // 전역에서 줄이지 않고 각 레이아웃이 확대 글자에 적응합니다.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: backgroundGradient),
              child: _DeeplinkBridge(
                router: router,
                child: InAppNotificationBannerOverlay(
                  child: _MandatoryConsentGate(
                    child: _TelemetryLifecycleBridge(
                      child: _NotificationsLifecycleBridge(
                        child: _ConnectivityWrapper(
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// EN: Parse theme mode string to ThemeMode enum
  /// KO: 테마 모드 문자열을 ThemeMode 열거형으로 파싱
  ThemeMode _parseThemeMode(String mode) {
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void _trackScreenViewIfNeeded({
    required WidgetRef ref,
    required GoRouter router,
  }) {
    final path = router.routeInformationProvider.value.uri.path;
    if (path.isEmpty || path == _lastTrackedScreenPath) {
      return;
    }
    _lastTrackedScreenPath = path;
    final screenName = _normalizeScreenName(path);
    unawaited(ref.read(analyticsServiceProvider).logScreenView(screenName));
    // EN: Enqueue SCREEN_VIEW telemetry event for server-side tracking.
    // KO: 서버 측 추적을 위해 SCREEN_VIEW 텔레메트리 이벤트를 큐에 추가합니다.
    ref
        .read(telemetryServiceProvider)
        .enqueue(
          TelemetryEventTypes.screenView,
          payload: {'screenName': screenName},
        );
  }

  String _normalizeScreenName(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    if (normalizedPath.isEmpty) {
      return 'root';
    }
    final segments = normalizedPath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) {
          final lower = segment.toLowerCase();
          if (_isUuidLike(lower) || _isNumericLike(lower)) {
            return 'id';
          }
          return lower.replaceAll('-', '_');
        })
        .toList(growable: false);
    return segments.join('_');
  }

  bool _isUuidLike(String value) {
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    return uuidPattern.hasMatch(value);
  }

  bool _isNumericLike(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }

  void _handleLocalNotificationTap({
    required WidgetRef ref,
    required GoRouter router,
    required LocalNotificationTapEvent tapEvent,
    required _NotificationTapSource source,
  }) {
    final notifier = ref.read(notificationsControllerProvider.notifier);
    if (tapEvent.notificationId.isNotEmpty) {
      unawaited(notifier.markAsRead(tapEvent.notificationId, refresh: false));
      if (source == _NotificationTapSource.localNotification) {
        unawaited(
          ref
              .read(remotePushServiceProvider)
              .trackNotificationOpen(tapEvent.notificationId),
        );
      }
    }

    final normalizedType = normalizeNotificationType(tapEvent.type);
    // EN: Ensure title caches are fresh before navigating so the title picker
    //     reflects earned titles granted since the last cache population.
    // KO: 탭 후 이동 전 칭호 캐시를 무효화하여 마지막 캐시 이후 부여된
    //     칭호가 칭호 피커에 반영되도록 합니다.
    if (normalizedType == notificationTypeTitleEarned) {
      unawaited(
        ref.read(titlesRepositoryProvider.future).then((repo) async {
          await repo.invalidateTitleCaches();
          unawaited(ref.read(activeTitleProvider.notifier).refresh());
        }),
      );
    }

    final targetPath =
        resolveNotificationNavigationPath(
          type: tapEvent.type,
          deeplink: tapEvent.deeplink,
          actionUrl: tapEvent.actionUrl,
          entityId: tapEvent.entityId,
        ) ??
        '/notifications';

    final currentPath = router.routeInformationProvider.value.uri.path;
    if (currentPath != targetPath) {
      router.go(targetPath);
    }
    unawaited(notifier.refreshInBackground(minInterval: Duration.zero));
  }
}

/// EN: Mandatory consent gate overlay for authenticated users.
/// KO: 인증 사용자 대상 필수 동의 게이트 오버레이입니다.
class _MandatoryConsentGate extends ConsumerWidget {
  const _MandatoryConsentGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final state = ref.watch(mandatoryConsentControllerProvider);

    final shouldBlockForLoading =
        isAuthenticated &&
        (!state.hasResolved || (state.isLoading && !state.isRequired));
    final shouldShowConsentOverlay = isAuthenticated && state.isRequired;

    if (!shouldBlockForLoading && !shouldShowConsentOverlay) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ColoredBox(
            color: shouldShowConsentOverlay
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.1),
            child: shouldShowConsentOverlay
                ? SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(GBTSpacing.md),
                        child: _MandatoryConsentOverlay(
                          requiredConsents: state.requiredConsents,
                        ),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _MandatoryConsentOverlay extends ConsumerStatefulWidget {
  const _MandatoryConsentOverlay({required this.requiredConsents});

  final List<RequiredConsentStatusItem> requiredConsents;

  @override
  ConsumerState<_MandatoryConsentOverlay> createState() =>
      _MandatoryConsentOverlayState();
}

class _MandatoryConsentOverlayState
    extends ConsumerState<_MandatoryConsentOverlay> {
  late Map<String, bool> _agreedByType;

  @override
  void initState() {
    super.initState();
    _syncAgreementState(initial: true);
  }

  @override
  void didUpdateWidget(covariant _MandatoryConsentOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.requiredConsents, widget.requiredConsents)) {
      _syncAgreementState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mandatoryConsentControllerProvider);
    final blockingTypes = state.requiredConsents
        .where(isBlockingRequiredConsent)
        .map((item) => item.type)
        .toSet();
    final canSubmit =
        !state.isSubmitting &&
        blockingTypes.isNotEmpty &&
        blockingTypes.every((type) => _agreedByType[type] == true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasConsentItems = widget.requiredConsents.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Material(
        color: isDark ? GBTColors.darkSurfaceElevated : GBTColors.surface,
        elevation: 10,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(GBTSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n(
                  ko: '서비스 이용을 위해 동의가 필요해요',
                  en: 'Consent is required to continue',
                  ja: 'サービス利用には同意が必要です',
                ),
                style: GBTTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GBTSpacing.sm),
              Text(
                context.l10n(
                  ko: '이용약관·개인정보 처리방침·위치정보 이용약관 동의 전에는 앱을 사용할 수 없습니다.',
                  en: 'You cannot use the app until all required terms, privacy, and location consents are accepted.',
                  ja: '利用規約・プライバシーポリシー・位置情報利用規約への同意前はアプリを利用できません。',
                ),
                style: GBTTypography.bodySmall,
              ),
              const SizedBox(height: GBTSpacing.md),
              if (hasConsentItems)
                ...widget.requiredConsents.indexed.map((entry) {
                  final index = entry.$1;
                  final consent = entry.$2;
                  final isRequired = isBlockingRequiredConsent(consent);
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == widget.requiredConsents.length - 1
                          ? 0
                          : GBTSpacing.xs,
                    ),
                    child: _MandatoryConsentCheckTile(
                      title: _consentTypeLabel(context, consent.type),
                      version: consent.requiredVersion,
                      checked: _agreedByType[consent.type] ?? !isRequired,
                      enabled: isRequired && !state.isSubmitting,
                      isRequired: isRequired,
                      onChanged: (value) {
                        if (!isRequired) return;
                        setState(() {
                          _agreedByType = {
                            ..._agreedByType,
                            consent.type: value ?? false,
                          };
                        });
                      },
                      onOpenPolicy: consent.policyUrl.isEmpty
                          ? null
                          : () => _openPolicy(context, consent.policyUrl),
                    ),
                  );
                }),
              if (state.errorMessage != null) ...[
                const SizedBox(height: GBTSpacing.sm),
                Text(
                  state.errorMessage!,
                  style: GBTTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (state.errorCode != null) ...[
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  'code: ${state.errorCode}',
                  style: GBTTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (state.requestId != null) ...[
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  'requestId: ${state.requestId}',
                  style: GBTTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: GBTSpacing.md),
              if (!hasConsentItems)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(mandatoryConsentControllerProvider.notifier)
                              .refresh(),
                    child: Text(
                      context.l10n(
                        ko: '동의 상태 다시 확인',
                        en: 'Retry consent status',
                        ja: '同意状態を再確認',
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            context.l10n(
                              ko: '동의하고 계속',
                              en: 'Agree and continue',
                              ja: '同意して続行',
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _consentTypeLabel(BuildContext context, String type) {
    return switch (type.toUpperCase()) {
      'TERMS_OF_SERVICE' => context.l10n(
        ko: '이용약관',
        en: 'Terms of service',
        ja: '利用規約',
      ),
      'PRIVACY_POLICY' => context.l10n(
        ko: '개인정보 처리방침',
        en: 'Privacy policy',
        ja: 'プライバシーポリシー',
      ),
      'LOCATION_TERMS' => context.l10n(
        ko: '위치정보 이용약관',
        en: 'Location terms',
        ja: '位置情報利用規約',
      ),
      _ => type,
    };
  }

  void _syncAgreementState({bool initial = false}) {
    final next = <String, bool>{};
    for (final consent in widget.requiredConsents) {
      if (!isBlockingRequiredConsent(consent)) {
        next[consent.type] = true;
        continue;
      }
      if (!initial && _agreedByType.containsKey(consent.type)) {
        next[consent.type] = _agreedByType[consent.type] ?? false;
      } else {
        next[consent.type] = false;
      }
    }
    _agreedByType = next;
  }

  Future<void> _submit() async {
    final success = await ref
        .read(mandatoryConsentControllerProvider.notifier)
        .submitRequiredConsents(agreedByType: _agreedByType);
    if (!mounted || success) return;
    final latestState = ref.read(mandatoryConsentControllerProvider);
    final message =
        latestState.errorMessage ??
        context.l10n(
          ko: '동의 제출에 실패했습니다. 다시 시도해주세요.',
          en: 'Failed to submit consent. Please retry.',
          ja: '同意の送信に失敗しました。再試行してください。',
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPolicy(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '정책 문서를 열 수 없습니다.',
            en: 'Unable to open policy document.',
            ja: 'ポリシー文書を開けません。',
          ),
        ),
      ),
    );
  }
}

class _MandatoryConsentCheckTile extends StatelessWidget {
  const _MandatoryConsentCheckTile({
    required this.title,
    required this.version,
    required this.checked,
    required this.enabled,
    required this.isRequired,
    required this.onChanged,
    required this.onOpenPolicy,
  });

  final String title;
  final String version;
  final bool checked;
  final bool enabled;
  final bool isRequired;
  final ValueChanged<bool?> onChanged;
  final VoidCallback? onOpenPolicy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(GBTSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Checkbox(value: checked, onChanged: enabled ? onChanged : null),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GBTSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRequired
                        ? '$title ${context.l10n(ko: '(재동의 필요)', en: '(reconsent required)', ja: '(再同意が必要)')}'
                        : title,
                    style: GBTTypography.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    version,
                    style: GBTTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onOpenPolicy,
            child: Text(context.l10n(ko: '보기', en: 'View', ja: '表示')),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// EN: Telemetry lifecycle bridge — APP_FOREGROUND / APP_BACKGROUND events.
// KO: 텔레메트리 라이프사이클 브리지 — APP_FOREGROUND / APP_BACKGROUND 이벤트.
// ────────────────────────────────────────────────────────────

class _TelemetryLifecycleBridge extends ConsumerStatefulWidget {
  const _TelemetryLifecycleBridge({required this.child});

  final Widget child;

  @override
  ConsumerState<_TelemetryLifecycleBridge> createState() =>
      _TelemetryLifecycleBridgeState();
}

class _TelemetryLifecycleBridgeState
    extends ConsumerState<_TelemetryLifecycleBridge>
    with WidgetsBindingObserver {
  DateTime? _foregroundEnteredAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foregroundEnteredAt = DateTime.now();
    // EN: Record initial foreground entry when app first launches.
    // KO: 앱 최초 실행 시 포그라운드 진입을 기록합니다.
    _enqueueAppForeground();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final telemetry = ref.read(telemetryServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        _foregroundEnteredAt = DateTime.now();
        _enqueueAppForeground();
        break;
      case AppLifecycleState.paused:
        final sessionSec = _foregroundEnteredAt != null
            ? DateTime.now().difference(_foregroundEnteredAt!).inSeconds
            : 0;
        telemetry.enqueue(
          TelemetryEventTypes.appBackground,
          payload: {'sessionDurationSec': sessionSec},
        );
        // EN: Flush queue immediately on background transition.
        //     Auth token is read directly from SecureStorage to avoid
        //     a Riverpod dependency on async futures inside a sync callback.
        // KO: 백그라운드 전환 즉시 큐를 플러시합니다.
        //     동기 콜백 내에서 비동기 Riverpod 의존을 피하기 위해
        //     SecureStorage에서 직접 액세스 토큰을 읽습니다.
        unawaited(_flushWithToken(telemetry));
        break;
      case AppLifecycleState.detached:
        unawaited(_flushWithToken(telemetry));
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _enqueueAppForeground() {
    ref
        .read(telemetryServiceProvider)
        .enqueue(
          TelemetryEventTypes.appForeground,
          payload: {
            'locale':
                ref.read(localeProvider)?.toLanguageTag() ??
                WidgetsBinding.instance.platformDispatcher.locale
                    .toLanguageTag(),
          },
        );
  }

  Future<void> _flushWithToken(TelemetryService telemetry) async {
    final token = await ref.read(secureStorageProvider).getAccessToken();
    await telemetry.flush(authToken: token);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// EN: Lifecycle bridge to enforce SSE single-connection policy per app session.
/// KO: 앱 세션 단일 SSE 연결 정책을 강제하는 라이프사이클 브리지입니다.
class _NotificationsLifecycleBridge extends ConsumerStatefulWidget {
  const _NotificationsLifecycleBridge({required this.child});

  final Widget child;

  @override
  ConsumerState<_NotificationsLifecycleBridge> createState() =>
      _NotificationsLifecycleBridgeState();
}

class _NotificationsLifecycleBridgeState
    extends ConsumerState<_NotificationsLifecycleBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(isAuthenticatedProvider)) {
      return;
    }
    final notifier = ref.read(notificationsControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(notifier.startRealtimeSync());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(notifier.stopRealtimeSync());
        break;
      case AppLifecycleState.inactive:
        // EN: Ignore transient inactive transitions.
        // KO: 일시적 inactive 전환은 무시합니다.
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// EN: Wrapper widget for connectivity status display
/// KO: 연결 상태 표시를 위한 래퍼 위젯
class _ConnectivityWrapper extends ConsumerStatefulWidget {
  const _ConnectivityWrapper({required this.child});

  final Widget child;

  @override
  ConsumerState<_ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<_ConnectivityWrapper> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _isOffline = _resolveOffline(ref.read(connectivityStatusProvider));
  }

  bool _resolveOffline(AsyncValue<ConnectivityStatus> value) {
    return value.valueOrNull == ConnectivityStatus.offline;
  }

  void _scheduleOfflineUpdate(bool isOffline) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOffline == isOffline) return;
      setState(() => _isOffline = isOffline);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOfflineNow = _resolveOffline(ref.watch(connectivityStatusProvider));
    if (isOfflineNow != _isOffline) {
      _scheduleOfflineUpdate(isOfflineNow);
    }

    // EN: Keep Positioned wrapper stable to avoid parentData dirty during
    // semantics flush — only swap the content inside.
    // KO: semantics flush 중 parentData dirty를 방지하기 위해 Positioned 래퍼를
    // 안정적으로 유지 — 내부 콘텐츠만 교체.
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _isOffline
              ? IgnorePointer(child: _OfflineBanner())
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// EN: Deeplink bridge — handles custom URL scheme girlsbandtabi://.
// KO: 딥링크 브리지 — 커스텀 URL 스킴 girlsbandtabi://를 처리합니다.
// ────────────────────────────────────────────────────────────

class _DeeplinkBridge extends StatefulWidget {
  const _DeeplinkBridge({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<_DeeplinkBridge> createState() => _DeeplinkBridgeState();
}

class _DeeplinkBridgeState extends State<_DeeplinkBridge> {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeeplinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initDeeplinks() async {
    _appLinks = AppLinks();

    // EN: Handle cold-start deeplink (app launched by tapping the link).
    // KO: 콜드 스타트 딥링크 처리 (링크를 탭하여 앱이 실행된 경우).
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null && mounted) {
        _handleDeeplink(initialUri);
      }
    } catch (_) {
      // EN: Ignore initial link errors (e.g., no link on normal launch).
      // KO: 초기 링크 오류 무시 (예: 일반 실행 시 링크 없음).
    }

    // EN: Handle foreground deeplinks while the app is running.
    // KO: 앱 실행 중 포그라운드 딥링크 처리.
    _linkSub = _appLinks!.uriLinkStream.listen((uri) {
      if (mounted) _handleDeeplink(uri);
    }, onError: (_) {});
  }

  void _handleDeeplink(Uri uri) {
    // EN: X (Twitter) PKCE OAuth callback — received as a Universal Link / App Link.
    //     iOS: Associated Domains (applinks:api.noraneko.cc) intercepts
    //          https://api.noraneko.cc/oauth/x/callback and delivers it here.
    //     Android: App Links (android:autoVerify="true") does the same.
    //     Routes to /auth/callback so OAuthCallbackPage can call completeTwitterLogin().
    // KO: X (Twitter) PKCE OAuth 콜백 — Universal Link / App Link로 수신됩니다.
    //     iOS: Associated Domains(applinks:api.noraneko.cc)이
    //          https://api.noraneko.cc/oauth/x/callback을 가로채 여기로 전달합니다.
    //     Android: App Links(android:autoVerify="true")가 동일하게 처리합니다.
    //     OAuthCallbackPage가 completeTwitterLogin()을 호출하도록 /auth/callback으로 라우팅합니다.
    if (uri.scheme == 'https' &&
        uri.host == 'api.noraneko.cc' &&
        uri.path == '/oauth/x/callback') {
      final code = uri.queryParameters['code'] ?? '';
      final stateParam = uri.queryParameters['state'];
      final query = StringBuffer(
        '?provider=twitter&code=${Uri.encodeComponent(code)}',
      );
      if (stateParam != null && stateParam.isNotEmpty) {
        query.write('&state=${Uri.encodeComponent(stateParam)}');
      }
      widget.router.go('/auth/callback$query');
      return;
    }

    if (uri.scheme != 'girlsbandtabi') return;

    if (uri.host == 'email-verified') {
      widget.router.go('/email-verified');
      return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// EN: Offline status banner widget
/// KO: 오프라인 상태 배너 위젯
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.error,
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 16,
                color: Theme.of(context).colorScheme.onError,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n(
                  ko: '오프라인 모드 - 일부 기능이 제한됩니다',
                  en: 'Offline mode - some features are limited',
                  ja: 'オフラインモード - 一部機能は制限されます',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
