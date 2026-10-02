/// EN: Composition root wiring [PlaceDetailPage] to the visit verification
///     sheet and the post-verification review link.
/// KO: [PlaceDetailPage]를 방문 인증 바텀시트와 인증 후 후기 작성 링크에
///     연결하는 composition root.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_text.dart';
import '../../../features/places/presentation/pages/place_detail_page.dart';
import '../../../features/places/presentation/widgets/place_review_sheet.dart';
import '../../../features/verification/application/verification_controller.dart';
import '../../../features/verification/presentation/widgets/verification_sheet.dart';

class PlaceVerificationFlow extends StatelessWidget {
  const PlaceVerificationFlow({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    return PlaceDetailPage(placeId: placeId, onVerify: _showVerificationSheet);
  }

  static void _showVerificationSheet(
    BuildContext context,
    WidgetRef ref,
    String placeId, {
    String? placeName,
  }) {
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
