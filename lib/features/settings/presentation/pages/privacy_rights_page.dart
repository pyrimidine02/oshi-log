/// EN: Privacy and data-rights page for user self-service actions.
/// KO: 사용자 셀프서비스 개인정보/권리행사 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/localization/locale_text.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/theme/gbt_typography.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/dialogs/gbt_adaptive_dialog.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../../core/widgets/sheets/gbt_bottom_sheet.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/settings_controller.dart';
import '../../domain/entities/privacy_rights.dart';
import '../widgets/field_settings_components.dart';

class PrivacyRightsPage extends ConsumerStatefulWidget {
  const PrivacyRightsPage({super.key});

  @override
  ConsumerState<PrivacyRightsPage> createState() => _PrivacyRightsPageState();
}

class _PrivacyRightsPageState extends ConsumerState<PrivacyRightsPage> {
  bool _isLoading = true;
  bool _autoTranslationEnabled = true;
  int? _privacySettingsVersion;
  DateTime? _privacySettingsUpdatedAt;
  bool _isSavingTranslation = false;
  bool _isDeletingAccount = false;
  List<PrivacyRequestRecord> _privacyRequests = const [];
  final TextEditingController _restrictionReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrivacyState();
  }

  @override
  void dispose() {
    _restrictionReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacyState() async {
    final storage = await ref.read(localStorageProvider.future);
    final localValue = storage.getBool(LocalStorageKeys.autoTranslationEnabled);
    final repository = await ref.read(settingsRepositoryProvider.future);
    final settingsResult = await repository.getPrivacySettings();
    final requestsResult = await repository.getPrivacyRequests();

    final resolvedSettings = settingsResult.dataOrNull;
    final resolvedRequests = requestsResult.dataOrNull ?? const [];

    if (resolvedSettings != null) {
      await storage.setBool(
        LocalStorageKeys.autoTranslationEnabled,
        resolvedSettings.allowAutoTranslation,
      );
    }

    if (!mounted) return;
    setState(() {
      _autoTranslationEnabled =
          resolvedSettings?.allowAutoTranslation ?? localValue ?? true;
      _privacySettingsVersion = resolvedSettings?.version;
      _privacySettingsUpdatedAt = resolvedSettings?.updatedAt;
      _privacyRequests = resolvedRequests;
      _isLoading = false;
    });
  }

  Future<void> _toggleAutoTranslation(bool value) async {
    final previous = _autoTranslationEnabled;
    setState(() {
      _autoTranslationEnabled = value;
      _isSavingTranslation = true;
    });

    final storage = await ref.read(localStorageProvider.future);
    await storage.setBool(LocalStorageKeys.autoTranslationEnabled, value);

    final repository = await ref.read(settingsRepositoryProvider.future);
    final result = await repository.updatePrivacySettings(
      allowAutoTranslation: value,
      version: _privacySettingsVersion,
    );

    if (!mounted) return;
    if (result is Err<PrivacySettings>) {
      setState(() {
        _autoTranslationEnabled = previous;
        _isSavingTranslation = false;
      });
      if (_isPrivacySettingsVersionConflict(result.failure)) {
        await _reloadPrivacySettings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n(
                ko: '다른 기기에서 설정이 변경되어 최신값으로 다시 불러왔어요.',
                en: 'Settings were updated elsewhere. Synced latest values.',
                ja: '他の端末で設定が変更されたため、最新値を再読み込みしました。',
              ),
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '자동번역 설정을 저장하지 못했어요. 잠시 후 다시 시도해주세요.',
              en: 'Failed to save auto-translation setting. Please retry.',
              ja: '自動翻訳設定の保存に失敗しました。しばらくして再試行してください。',
            ),
          ),
        ),
      );
      return;
    }

    final payload = result.dataOrNull!;
    setState(() {
      _isSavingTranslation = false;
      _autoTranslationEnabled = payload.allowAutoTranslation;
      _privacySettingsVersion = payload.version;
      _privacySettingsUpdatedAt = payload.updatedAt;
    });

    await storage.setBool(
      LocalStorageKeys.autoTranslationEnabled,
      payload.allowAutoTranslation,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '자동번역 설정이 저장되었습니다.',
            en: 'Auto-translation setting saved.',
            ja: '自動翻訳設定を保存しました。',
          ),
        ),
      ),
    );
  }

  Future<void> _requestProcessingRestriction() async {
    final reason = _restrictionReasonController.text.trim();
    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '처리정지 사유를 10자 이상 입력해주세요.',
              en: 'Please enter at least 10 characters for the reason.',
              ja: '処理停止理由を10文字以上入力してください。',
            ),
          ),
        ),
      );
      return;
    }

    final repository = await ref.read(settingsRepositoryProvider.future);
    final remoteResult = await repository.createPrivacyRequest(
      requestType: 'RESTRICTION',
      reason: reason,
    );

    _restrictionReasonController.clear();
    if (!mounted) return;
    Navigator.of(context).pop();

    if (remoteResult is Success<PrivacyRequestRecord>) {
      setState(() {
        _privacyRequests = [remoteResult.data, ..._privacyRequests];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '처리정지 요청이 접수되었습니다.',
              en: 'Restriction request submitted.',
              ja: '処理停止要請を受け付けました。',
            ),
          ),
        ),
      );
      return;
    }

    final failure = (remoteResult as Err<PrivacyRequestRecord>).failure;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_privacyRequestFailureMessage(failure, context))),
    );
  }

  Future<void> _reloadPrivacySettings() async {
    final repository = await ref.read(settingsRepositoryProvider.future);
    final storage = await ref.read(localStorageProvider.future);
    final result = await repository.getPrivacySettings(forceRefresh: true);
    final payload = result.dataOrNull;
    if (payload == null || !mounted) return;
    await storage.setBool(
      LocalStorageKeys.autoTranslationEnabled,
      payload.allowAutoTranslation,
    );
    if (!mounted) return;
    setState(() {
      _autoTranslationEnabled = payload.allowAutoTranslation;
      _privacySettingsVersion = payload.version;
      _privacySettingsUpdatedAt = payload.updatedAt;
    });
  }

  bool _isPrivacySettingsVersionConflict(Failure failure) {
    final code = failure.code?.trim().toUpperCase();
    if (code == 'PRIVACY_SETTINGS_VERSION_CONFLICT') {
      return true;
    }
    return failure.message.toUpperCase().contains(
      'PRIVACY_SETTINGS_VERSION_CONFLICT',
    );
  }

  String _privacyRequestFailureMessage(Failure failure, BuildContext context) {
    final code = failure.code?.trim().toUpperCase();
    switch (code) {
      case 'PRIVACY_REQUEST_DUPLICATED':
        return context.l10n(
          ko: '같은 유형의 요청이 이미 진행 중입니다.',
          en: 'A similar request is already in progress.',
          ja: '同種の要請がすでに進行中です。',
        );
      case 'PRIVACY_REQUEST_RATE_LIMITED':
        return context.l10n(
          ko: '요청이 너무 잦습니다. 잠시 후 다시 시도해주세요.',
          en: 'Too many requests. Please try again later.',
          ja: '要求頻度が高すぎます。しばらくしてから再試行してください。',
        );
      case 'PRIVACY_REQUEST_INVALID':
        return context.l10n(
          ko: '요청 정보가 올바르지 않습니다. 입력값을 확인해주세요.',
          en: 'Invalid request payload. Please check your input.',
          ja: '要請情報が正しくありません。入力内容を確認してください。',
        );
      default:
        return context.l10n(
          ko: '처리정지 요청을 접수하지 못했어요. 잠시 후 다시 시도해주세요.',
          en: 'Failed to submit restriction request. Please retry.',
          ja: '処理停止要請の受付に失敗しました。しばらくして再試行してください。',
        );
    }
  }

  Future<void> _showProcessingRestrictionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            context.l10n(
              ko: '처리정지 요청',
              en: 'Request processing restriction',
              ja: '処理停止要請',
            ),
          ),
          content: TextField(
            controller: _restrictionReasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: context.l10n(
                ko: '요청 사유를 입력해주세요 (최소 10자)',
                en: 'Enter the reason (minimum 10 characters)',
                ja: '要請理由を入力してください（10文字以上）',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル')),
            ),
            FilledButton(
              onPressed: _requestProcessingRestriction,
              child: Text(
                context.l10n(ko: '요청하기', en: 'Submit request', ja: '要請する'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showGBTAdaptiveConfirmDialog(
      context: context,
      title: context.l10n(ko: '회원 탈퇴', en: 'Delete account', ja: 'アカウント削除'),
      message: context.l10n(
        ko: '탈퇴 시 계정 접근이 차단되며, 일부 데이터는 관련 법령 및 운영정책에 따라 일정 기간 보관 후 파기됩니다.\n정말 진행할까요?',
        en: 'Deleting your account blocks access. Some data may be retained for a limited legal/operational period before deletion.\nDo you want to continue?',
        ja: '退会するとアカウントアクセスが停止されます。一部データは法令・運用方針に基づき一定期間保管後に削除されます。\n続行しますか？',
      ),
      cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
      confirmLabel: context.l10n(ko: '탈퇴 진행', en: 'Delete account', ja: '削除する'),
      isDestructive: true,
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isDeletingAccount = true);

    final repository = await ref.read(settingsRepositoryProvider.future);
    final result = await repository.deleteAccount();

    if (!mounted) return;

    if (result is Err<void>) {
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n(
              ko: '탈퇴 처리에 실패했습니다. 잠시 후 다시 시도해주세요.',
              en: 'Failed to delete account. Please try again shortly.',
              ja: 'アカウント削除に失敗しました。しばらくしてから再試行してください。',
            ),
          ),
        ),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    setState(() => _isDeletingAccount = false);
    context.go('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // EN: Inform the user that deactivation is pending purge (30-day grace).
        // KO: 30일 유예기간 내 계정 복구가 가능함을 안내합니다.
        content: Text(
          context.l10n(
            ko: '탈퇴 신청이 완료되었습니다. 30일 이내에 재로그인하면 계정을 복구할 수 있습니다.',
            en: 'Account deactivation requested. You can restore your account within 30 days by logging in again.',
            ja: '退会申請が完了しました。30日以内に再ログインすることでアカウントを復元できます。',
          ),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: gbtStandardAppBar(
          context,
          title: context.l10n(
            ko: '개인정보 및 권리행사',
            en: 'Privacy and rights',
            ja: 'プライバシーと権利行使',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: context.l10n(
          ko: '개인정보 및 권리행사',
          en: 'Privacy and rights',
          ja: 'プライバシーと権利行使',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(GBTSpacing.md),
        children: [
          _SectionCard(
            title: context.l10n(
              ko: '자동번역 전송 설정',
              en: 'Auto-translation transfer',
              ja: '自動翻訳転送設定',
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoTranslationEnabled,
                  onChanged: _isSavingTranslation
                      ? null
                      : _toggleAutoTranslation,
                  title: Text(
                    context.l10n(
                      ko: '커뮤니티 자동번역 허용',
                      en: 'Allow community auto-translation',
                      ja: 'コミュニティ自動翻訳を許可',
                    ),
                    style: GBTTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n(
                      ko: '끄면 외부 번역 서비스 전송을 중단합니다.',
                      en: 'When off, external translation transfer is disabled.',
                      ja: 'オフにすると外部翻訳サービスへの転送を停止します。',
                    ),
                    style: GBTTypography.bodySmall,
                  ),
                ),
                if (_privacySettingsUpdatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: GBTSpacing.xs),
                    child: Text(
                      context.l10n(
                        ko:
                            '최종 반영: ${_formatDateTime(_privacySettingsUpdatedAt!)}'
                            '${_privacySettingsVersion != null ? ' · v$_privacySettingsVersion' : ''}',
                        en:
                            'Updated: ${_formatDateTime(_privacySettingsUpdatedAt!)}'
                            '${_privacySettingsVersion != null ? ' · v$_privacySettingsVersion' : ''}',
                        ja:
                            '最終反映: ${_formatDateTime(_privacySettingsUpdatedAt!)}'
                            '${_privacySettingsVersion != null ? ' · v$_privacySettingsVersion' : ''}',
                      ),
                      style: GBTTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: GBTSpacing.md),
          _SectionCard(
            title: context.l10n(
              ko: '권리행사 요청 이력',
              en: 'Rights request history',
              ja: '権利行使要請履歴',
            ),
            child: _privacyRequests.isEmpty
                ? Text(
                    context.l10n(
                      ko: '최근 요청 이력이 없습니다.',
                      en: 'No recent rights requests.',
                      ja: '最近の要請履歴はありません。',
                    ),
                    style: GBTTypography.bodySmall,
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _privacyRequests.length && i < 5; i++)
                        _PrivacyRequestRow(item: _privacyRequests[i]),
                    ],
                  ),
          ),
          const SizedBox(height: GBTSpacing.md),
          _SectionCard(
            title: context.l10n(
              ko: '정보주체 권리행사',
              en: 'Data subject rights',
              ja: '情報主体の権利行使',
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.visibility_outlined),
                  title: Text(
                    context.l10n(
                      ko: '내 데이터 열람',
                      en: 'View my data',
                      ja: 'マイデータ閲覧',
                    ),
                  ),
                  subtitle: Text(
                    context.l10n(
                      ko: '프로필/방문기록/즐겨찾기로 이동',
                      en: 'Open profile/visits/favorites',
                      ja: 'プロフィール・訪問履歴・お気に入りへ移動',
                    ),
                    style: GBTTypography.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDataViewLinks(),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pause_circle_outline_rounded),
                  title: Text(
                    context.l10n(
                      ko: '처리정지 요청',
                      en: 'Request processing restriction',
                      ja: '処理停止要請',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showProcessingRestrictionDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: GBTColors.error,
                  ),
                  title: Text(
                    context.l10n(
                      ko: '회원 탈퇴',
                      en: 'Delete account',
                      ja: 'アカウント削除',
                    ),
                    style: const TextStyle(color: GBTColors.error),
                  ),
                  trailing: _isDeletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _isDeletingAccount ? null : _deleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDataViewLinks() {
    showGBTBottomSheet<void>(
      context: context,
      title: context.l10n(ko: '내 데이터 열람', en: 'View my data', ja: 'データ閲覧'),
      child: Builder(
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(
                    context.l10n(ko: '프로필 정보', en: 'Profile', ja: 'プロフィール'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    this.context.push('/settings/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: Text(
                    context.l10n(ko: '방문 기록', en: 'Visit history', ja: '訪問履歴'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    this.context.push('/visits');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border_rounded),
                  title: Text(
                    context.l10n(ko: '즐겨찾기', en: 'Favorites', ja: 'お気に入り'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    this.context.push('/favorites');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

class _PrivacyRequestRow extends StatelessWidget {
  const _PrivacyRequestRow({required this.item});

  final PrivacyRequestRecord item;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.status.toUpperCase()) {
      'COMPLETED' => GBTColors.success,
      'REJECTED' => Theme.of(context).colorScheme.error,
      'IN_REVIEW' => GBTColors.warningDark,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.requestType,
                  style: GBTTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(item.requestedAt),
                  style: GBTTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.status,
              style: GBTTypography.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FieldSettingsSection(
      title: title,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.xs),
          child: child,
        ),
      ],
    );
  }
}
