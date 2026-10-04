/// EN: Composition root wiring [PlaceDetailPage] to the visit verification
///     sheet and the post-verification review link.
/// KO: [PlaceDetailPage]를 방문 인증 바텀시트와 인증 후 후기 작성 링크에
///     연결하는 composition root.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../platform/router/app_router.dart' show AppRoutes;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/features/identity/auth/application/auth_action_gate.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

import '../../../design_system/localization/locale_text.dart';
import '../today/application/today_controller.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/presentation/pages/place_detail_page.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/place_review_sheet.dart';
import 'package:oshi_log/features/place/verification/application/verification_controller.dart';
import 'package:oshi_log/features/place/verification/presentation/widgets/verification_sheet.dart';

class PlaceVerificationFlow extends ConsumerWidget {
  const PlaceVerificationFlow({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlaceDetailPage(
      placeId: placeId,
      onVerify: _showVerificationSheet,
      onAddToToday: (detail) => _addToToday(context, ref, detail),
    );
  }

  Future<void> _addToToday(
    BuildContext context,
    WidgetRef ref,
    PlaceDetail detail,
  ) async {
    // EN: Capture the successful fetch scope before opening authentication UI.
    // KO: 인증 UI를 열기 전에 실제 조회에 성공한 프로젝트 범위를 보존합니다.
    final projectKey = ref
        .read(placeDetailControllerProvider(placeId).notifier)
        .resolvedProjectKey;
    if (!ref.read(isAuthenticatedProvider) &&
        !await ref.read(authenticationGateProvider)(context)) {
      return;
    }
    if (!context.mounted) return;
    final saved =
        projectKey != null &&
        await ref
            .read(todayControllerProvider.notifier)
            .addDetail(projectKey: projectKey, detail: detail);
    if (!context.mounted) return;
    final needsDate =
        ref.read(todayControllerProvider).failure == TodayFailure.dateMismatch;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: SnackBarAction(
          label: context.l10n(ko: '목록 열기', en: 'Open list', ja: 'リストを開く'),
          onPressed: () => context.pushNamed(AppRoutes.today),
        ),
        content: Text(
          saved
              ? context.l10n(
                  ko: '오늘 목록에 저장했어요.',
                  en: 'Saved to Today.',
                  ja: '今日のリストに保存しました。',
                )
              : needsDate
              ? context.l10n(
                  ko: '오늘 목록을 열어 새 날짜를 확인해 주세요.',
                  en: 'Open Today to confirm a new date.',
                  ja: '今日のリストを開いて新しい日付を確認してください。',
                )
              : context.l10n(
                  ko: '오늘 목록에 저장하지 못했어요. 다시 시도해 주세요.',
                  en: 'Could not save to Today. Try again.',
                  ja: '今日のリストに保存できませんでした。もう一度お試しください。',
                ),
        ),
      ),
    );
  }

  static Future<void> _showVerificationSheet(
    BuildContext context,
    WidgetRef ref,
    String placeId, {
    String? placeName,
  }) async {
    if (!ref.read(isAuthenticatedProvider) &&
        !await ref.read(authenticationGateProvider)(context)) {
      return;
    }
    if (!context.mounted) return;
    ref.read(verificationControllerProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => VerificationSheet(
        title: context.l10n(ko: '방문 인증', en: 'Visit verification', ja: '訪問認証'),
        description: context.l10n(
          ko: '현재 위치를 확인해 방문 인증을 진행합니다.',
          en: 'Verify your current location to complete visit verification.',
          ja: '現在地を確認して訪問認証を進めます。',
        ),
        onVerify: () => ref
            .read(verificationControllerProvider.notifier)
            .verifyPlace(placeId, targetName: placeName),
        onWriteReview: () => _showReviewSheet(context, placeId),
      ),
    );
  }

  static void _showReviewSheet(BuildContext context, String placeId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PlaceReviewSheet(placeId: placeId),
    );
  }
}
