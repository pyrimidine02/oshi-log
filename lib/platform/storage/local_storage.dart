/// EN: Local storage for non-sensitive app data using SharedPreferences
/// KO: SharedPreferences를 사용한 비민감 앱 데이터용 로컬 저장소
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// EN: Keys for local storage
/// KO: 로컬 저장소 키
class LocalStorageKeys {
  LocalStorageKeys._();

  // EN: App Settings
  // KO: 앱 설정
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String notificationDeviceId = 'notification_device_id';
  static const String notificationDeviceIdLegacy = 'notifications_device_id';
  static const String notificationPushToken = 'notification_push_token';
  static const String userConsents = 'user_consents';
  // EN: Append-only log of location-notice consent actions (agree / revoke)
  //     with timestamps, so settings can show when consent was given or
  //     withdrawn.
  // KO: 위치 수집 고지 동의/철회 이력을 시각과 함께 append-only로 기록합니다.
  //     설정 화면에서 동의일과 철회일을 표시하기 위해 사용합니다.
  static const String locationNoticeConsentLog = 'location_notice_consent_log';
  static const String autoTranslationEnabled = 'auto_translation_enabled';
  static const String privacyRequestHistory = 'privacy_request_history';

  // EN: User Preferences
  // KO: 사용자 설정
  static const String selectedProjectId = 'selected_project_id';
  static const String selectedProjectKey = 'selected_project_key';
  static const String selectedUnitIds = 'selected_unit_ids';
  static const String recentSearches = 'recent_searches';
  static const String pendingFavoriteMutations = 'pending_favorite_mutations';
  static const String pendingPostReactionMutations =
      'pending_post_reaction_mutations';
  static const String pendingLiveAttendanceMutations =
      'pending_live_attendance_mutations';
  static const String localPostBookmarks = 'local_post_bookmarks';

  // EN: Cache Keys
  // KO: 캐시 키
  static const String lastSyncTime = 'last_sync_time';
  static const String cachedHomeData = 'cached_home_data';

  // EN: Verification failure log (local only)
  // KO: 인증 실패 로그 (로컬 전용)
  static const String failedVerificationAttempts =
      'failed_verification_attempts';
}

/// EN: Wrapper for SharedPreferences with typed methods
/// KO: 타입화된 메서드를 제공하는 SharedPreferences 래퍼
class LocalStorage {
  /// EN: Create a storage wrapper for an optional API-origin namespace.
  ///     A null namespace keeps the low-level wrapper compatible for tests and
  ///     migration tools; app providers always pass the captured namespace.
  /// KO: 선택적인 API 오리진 네임스페이스를 사용하는 저장소 래퍼를 생성합니다.
  ///     null 네임스페이스는 테스트와 마이그레이션 도구를 위한 저수준 호환성을
  ///     유지하며, 앱 프로바이더는 항상 캡처한 네임스페이스를 전달합니다.
  LocalStorage(this._prefs, {String? namespace})
    : _namespace = namespace?.trim().isEmpty == true ? null : namespace?.trim();

  final SharedPreferences _prefs;
  final String? _namespace;

  /// EN: Namespace used by this wrapper, if it is scoped.
  /// KO: 이 래퍼가 사용하는 네임스페이스입니다.
  String? get namespace => _namespace;

  /// EN: Create instance asynchronously
  /// KO: 비동기적으로 인스턴스 생성
  static Future<LocalStorage> create({String? namespace}) async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs, namespace: namespace);
  }

  String _storageKey(String key) {
    final namespace = _namespace;
    if (namespace == null || _isGlobalKey(key)) {
      return key;
    }
    if (key.startsWith('gbt:$namespace:')) {
      return key;
    }
    return 'gbt:$namespace:$key';
  }

  bool _isGlobalKey(String key) {
    return key == LocalStorageKeys.themeMode || key == LocalStorageKeys.locale;
  }

  bool _belongsToNamespace(String key) {
    final namespace = _namespace;
    if (namespace == null) {
      return true;
    }
    return key.startsWith('gbt:$namespace:');
  }

  // ========================================
  // EN: Theme Settings
  // KO: 테마 설정
  // ========================================

  /// EN: Get theme mode (light/dark/system)
  /// KO: 테마 모드 조회 (라이트/다크/시스템)
  String? getThemeMode() {
    return _prefs.getString(_storageKey(LocalStorageKeys.themeMode));
  }

  /// EN: Set theme mode
  /// KO: 테마 모드 설정
  Future<bool> setThemeMode(String mode) {
    return _prefs.setString(_storageKey(LocalStorageKeys.themeMode), mode);
  }

  // ========================================
  // EN: Locale Settings
  // KO: 로케일 설정
  // ========================================

  /// EN: Get locale code
  /// KO: 로케일 코드 조회
  String? getLocale() {
    return _prefs.getString(_storageKey(LocalStorageKeys.locale));
  }

  /// EN: Set locale code
  /// KO: 로케일 코드 설정
  Future<bool> setLocale(String locale) {
    return _prefs.setString(_storageKey(LocalStorageKeys.locale), locale);
  }

  // ========================================
  // EN: Onboarding Status
  // KO: 온보딩 상태
  // ========================================

  /// EN: Check if onboarding is completed
  /// KO: 온보딩 완료 여부 확인
  bool isOnboardingCompleted() {
    return _prefs.getBool(_storageKey(LocalStorageKeys.onboardingCompleted)) ??
        false;
  }

  /// EN: Set onboarding completed
  /// KO: 온보딩 완료 설정
  Future<bool> setOnboardingCompleted(bool completed) {
    return _prefs.setBool(
      _storageKey(LocalStorageKeys.onboardingCompleted),
      completed,
    );
  }

  // ========================================
  // EN: Project Selection
  // KO: 프로젝트 선택
  // ========================================

  /// EN: Get selected project key (slug/code)
  /// KO: 선택된 프로젝트 키(slug/code) 조회
  String? getSelectedProjectKey() {
    return _prefs.getString(_storageKey(LocalStorageKeys.selectedProjectKey));
  }

  /// EN: Set selected project key (slug/code)
  /// KO: 선택된 프로젝트 키(slug/code) 설정
  Future<bool> setSelectedProjectKey(String projectKey) {
    return _prefs.setString(
      _storageKey(LocalStorageKeys.selectedProjectKey),
      projectKey,
    );
  }

  /// EN: Get selected project ID (legacy)
  /// KO: 선택된 프로젝트 ID 조회 (레거시)
  String? getSelectedProjectId() {
    return _prefs.getString(_storageKey(LocalStorageKeys.selectedProjectId));
  }

  /// EN: Set selected project ID (legacy)
  /// KO: 선택된 프로젝트 ID 설정 (레거시)
  Future<bool> setSelectedProjectId(String projectId) {
    return _prefs.setString(
      _storageKey(LocalStorageKeys.selectedProjectId),
      projectId,
    );
  }

  /// EN: Get selected unit IDs
  /// KO: 선택된 유닛 ID 목록 조회
  List<String> getSelectedUnitIds() {
    return _prefs.getStringList(
          _storageKey(LocalStorageKeys.selectedUnitIds),
        ) ??
        [];
  }

  /// EN: Set selected unit IDs
  /// KO: 선택된 유닛 ID 목록 설정
  Future<bool> setSelectedUnitIds(List<String> unitIds) {
    return _prefs.setStringList(
      _storageKey(LocalStorageKeys.selectedUnitIds),
      unitIds,
    );
  }

  // ========================================
  // EN: Recent Searches
  // KO: 최근 검색
  // ========================================

  /// EN: Get recent searches
  /// KO: 최근 검색 목록 조회
  List<String> getRecentSearches() {
    return _prefs.getStringList(_storageKey(LocalStorageKeys.recentSearches)) ??
        [];
  }

  /// EN: Add search to recent searches (max 10)
  /// KO: 최근 검색에 추가 (최대 10개)
  Future<bool> addRecentSearch(String query) {
    final searches = getRecentSearches();
    searches.remove(query); // Remove if exists
    searches.insert(0, query); // Add to beginning
    if (searches.length > 10) {
      searches.removeLast();
    }
    return _prefs.setStringList(
      _storageKey(LocalStorageKeys.recentSearches),
      searches,
    );
  }

  /// EN: Clear recent searches
  /// KO: 최근 검색 삭제
  Future<bool> clearRecentSearches() {
    return _prefs.remove(_storageKey(LocalStorageKeys.recentSearches));
  }

  /// EN: Set recent searches list
  /// KO: 최근 검색 목록 설정
  Future<bool> setRecentSearches(List<String> searches) {
    return _prefs.setStringList(
      _storageKey(LocalStorageKeys.recentSearches),
      searches,
    );
  }

  /// EN: Remove a search query from recent searches
  /// KO: 최근 검색에서 특정 검색어 제거
  Future<bool> removeRecentSearch(String query) {
    final searches = getRecentSearches();
    searches.remove(query);
    return _prefs.setStringList(
      _storageKey(LocalStorageKeys.recentSearches),
      searches,
    );
  }

  /// EN: Get pending offline favorite mutations.
  /// KO: 오프라인 즐겨찾기 대기 작업을 조회합니다.
  List<Map<String, dynamic>> getPendingFavoriteMutations() {
    return getJsonList(
          _storageKey(LocalStorageKeys.pendingFavoriteMutations),
        ) ??
        const [];
  }

  /// EN: Persist pending offline favorite mutations.
  /// KO: 오프라인 즐겨찾기 대기 작업을 저장합니다.
  Future<bool> setPendingFavoriteMutations(List<Map<String, dynamic>> value) {
    return setJsonList(
      _storageKey(LocalStorageKeys.pendingFavoriteMutations),
      value,
    );
  }

  /// EN: Get pending offline post reaction mutations.
  /// KO: 오프라인 게시글 반응 대기 작업을 조회합니다.
  List<Map<String, dynamic>> getPendingPostReactionMutations() {
    return getJsonList(
          _storageKey(LocalStorageKeys.pendingPostReactionMutations),
        ) ??
        const [];
  }

  /// EN: Persist pending offline post reaction mutations.
  /// KO: 오프라인 게시글 반응 대기 작업을 저장합니다.
  Future<bool> setPendingPostReactionMutations(
    List<Map<String, dynamic>> value,
  ) {
    return setJsonList(
      _storageKey(LocalStorageKeys.pendingPostReactionMutations),
      value,
    );
  }

  /// EN: Get locally cached bookmarked posts.
  /// KO: 로컬 캐시에 저장된 북마크 게시글을 조회합니다.
  List<Map<String, dynamic>> getLocalPostBookmarks() {
    return getJsonList(_storageKey(LocalStorageKeys.localPostBookmarks)) ??
        const [];
  }

  /// EN: Persist locally cached bookmarked posts.
  /// KO: 북마크 게시글을 로컬 캐시에 저장합니다.
  Future<bool> setLocalPostBookmarks(List<Map<String, dynamic>> value) {
    return setJsonList(_storageKey(LocalStorageKeys.localPostBookmarks), value);
  }

  /// EN: Get pending offline live attendance mutations.
  /// KO: 오프라인 라이브 출석 대기 작업을 조회합니다.
  List<Map<String, dynamic>> getPendingLiveAttendanceMutations() {
    return getJsonList(
          _storageKey(LocalStorageKeys.pendingLiveAttendanceMutations),
        ) ??
        const [];
  }

  /// EN: Persist pending offline live attendance mutations.
  /// KO: 오프라인 라이브 출석 대기 작업을 저장합니다.
  Future<bool> setPendingLiveAttendanceMutations(
    List<Map<String, dynamic>> value,
  ) {
    return setJsonList(
      _storageKey(LocalStorageKeys.pendingLiveAttendanceMutations),
      value,
    );
  }

  // ========================================
  // EN: Cache Management
  // KO: 캐시 관리
  // ========================================

  /// EN: Get last sync time
  /// KO: 마지막 동기화 시간 조회
  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getInt(_storageKey(LocalStorageKeys.lastSyncTime));
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// EN: Set last sync time
  /// KO: 마지막 동기화 시간 설정
  Future<bool> setLastSyncTime(DateTime time) {
    return _prefs.setInt(
      _storageKey(LocalStorageKeys.lastSyncTime),
      time.millisecondsSinceEpoch,
    );
  }

  // ========================================
  // EN: Generic JSON Methods
  // KO: 제네릭 JSON 메서드
  // ========================================

  /// EN: Save JSON object
  /// KO: JSON 객체 저장
  Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _prefs.setString(_storageKey(key), jsonEncode(value));
  }

  /// EN: Get JSON object
  /// KO: JSON 객체 조회
  Map<String, dynamic>? getJson(String key) {
    final value = _prefs.getString(_storageKey(key));
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// EN: Save JSON list
  /// KO: JSON 리스트 저장
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) {
    return _prefs.setString(_storageKey(key), jsonEncode(value));
  }

  /// EN: Get JSON list
  /// KO: JSON 리스트 조회
  List<Map<String, dynamic>>? getJsonList(String key) {
    final value = _prefs.getString(_storageKey(key));
    if (value == null) return null;
    try {
      final list = jsonDecode(value) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  // ========================================
  // EN: Generic Methods
  // KO: 제네릭 메서드
  // ========================================

  /// EN: Set string value
  /// KO: 문자열 값 설정
  Future<bool> setString(String key, String value) {
    return _prefs.setString(_storageKey(key), value);
  }

  /// EN: Get string value
  /// KO: 문자열 값 조회
  String? getString(String key) {
    return _prefs.getString(_storageKey(key));
  }

  /// EN: Set int value
  /// KO: 정수 값 설정
  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(_storageKey(key), value);
  }

  /// EN: Get int value
  /// KO: 정수 값 조회
  int? getInt(String key) {
    return _prefs.getInt(_storageKey(key));
  }

  /// EN: Set bool value
  /// KO: 불리언 값 설정
  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(_storageKey(key), value);
  }

  /// EN: Get bool value
  /// KO: 불리언 값 조회
  bool? getBool(String key) {
    return _prefs.getBool(_storageKey(key));
  }

  /// EN: Remove value
  /// KO: 값 삭제
  Future<bool> remove(String key) {
    return _prefs.remove(_storageKey(key));
  }

  /// EN: Clear all data
  /// KO: 모든 데이터 삭제
  Future<bool> clearAll() async {
    var result = true;
    for (final key in getKeys()) {
      if (_isGlobalKey(key)) continue;
      result = await remove(key) && result;
    }
    return result;
  }

  /// EN: Check if key exists
  /// KO: 키 존재 여부 확인
  bool containsKey(String key) {
    return _prefs.containsKey(_storageKey(key));
  }

  /// EN: Returns all stored keys.
  ///     Scoped storage returns logical keys, hiding its physical namespace
  ///     prefix from cache and feature callers.
  /// KO: 저장된 모든 키를 반환합니다. 범위가 지정된 저장소는 캐시와 기능
  ///     호출자에게 물리적 네임스페이스 접두사를 숨기고 논리 키를 반환합니다.
  Set<String> getKeys() {
    final namespace = _namespace;
    final prefix = namespace == null ? null : 'gbt:$namespace:';
    return Set<String>.unmodifiable(
      _prefs
          .getKeys()
          .where(_belongsToNamespace)
          .map((key) => prefix != null ? key.substring(prefix.length) : key),
    );
  }
}
