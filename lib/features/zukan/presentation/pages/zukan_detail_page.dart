/// EN: Field-notes detail for one pilgrimage specimen collection.
/// KO: 하나의 성지순례 표본 컬렉션을 위한 필드 노트 상세 화면입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_text.dart';
import '../../../../core/widgets/feedback/gbt_empty_state.dart';
import '../../../../core/widgets/feedback/gbt_loading.dart' hide GBTEmptyState;
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../application/zukan_controller.dart';
import '../field_detail/field_zukan_detail_sections.dart';

/// EN: Displays a specimen file while preserving the existing detail provider.
/// KO: 기존 상세 프로바이더를 유지하며 표본 파일을 표시합니다.
class ZukanDetailPage extends ConsumerWidget {
  const ZukanDetailPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(
      zukanCollectionDetailProvider(collectionId),
    );
    final appBarTitle = collectionAsync.maybeWhen(
      data: (collection) => collection?.title,
      orElse: () => null,
    );

    return Scaffold(
      appBar: gbtStandardAppBar(
        context,
        title: appBarTitle?.trim().isNotEmpty == true
            ? appBarTitle!
            : context.l10n(ko: '도감', en: 'Collection', ja: '図鑑'),
      ),
      body: collectionAsync.when(
        loading: () => const Center(child: GBTLoading()),
        error: (_, __) => GBTEmptyState(
          icon: Icons.cloud_off_rounded,
          title: context.l10n(
            ko: '도감을 불러오지 못했어요',
            en: 'Could not load collection',
            ja: '図鑑を読み込めませんでした',
          ),
          actionLabel: context.l10n(ko: '다시 시도', en: 'Retry', ja: '再試行'),
          onAction: () =>
              ref.refresh(zukanCollectionDetailProvider(collectionId)),
        ),
        data: (collection) => collection == null
            ? GBTEmptyState(
                icon: Icons.search_off_rounded,
                title: context.l10n(
                  ko: '도감을 찾을 수 없어요',
                  en: 'Collection not found',
                  ja: '図鑑が見つかりません',
                ),
              )
            : FieldZukanDetailBody(collection: collection),
      ),
    );
  }
}
