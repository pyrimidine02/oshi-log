/// EN: Shared place directions action-sheet launcher.
/// KO: 장소 길안내 액션시트 공용 실행기.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/widgets/sheets/gbt_bottom_sheet.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';

Future<void> showPlaceDirectionsSheet(
  BuildContext context, {
  required String placeName,
  required PlaceDirections directions,
}) async {
  final orderedProviders = _prioritizeDirectionProviders(directions.providers);
  if (orderedProviders.isEmpty) return;

  await showGBTActionSheet<void>(
    context: context,
    title: context.l10n(
      ko: '$placeName 길안내',
      en: '$placeName directions',
      ja: '$placeName 経路案内',
    ),
    cancelLabel: context.l10n(ko: '취소', en: 'Cancel', ja: 'キャンセル'),
    actions: orderedProviders
        .map(
          (provider) => GBTActionSheetItem<void>(
            label: provider.label,
            icon: _directionProviderIcon(provider.provider),
            onTap: () => unawaited(
              _launchDirectionsUrl(
                context,
                provider.url,
                providerLabel: provider.label,
              ),
            ),
          ),
        )
        .toList(),
  );
}

/// EN: Reorder provider list per platform recommendation while keeping server URLs.
/// KO: 서버 URL을 유지한 채 플랫폼 권장 순서로 provider 목록을 재정렬합니다.
List<PlaceDirectionProvider> _prioritizeDirectionProviders(
  List<PlaceDirectionProvider> providers,
) {
  final sorted = [...providers];
  sorted.sort((a, b) {
    final aPriority = _providerPriority(a.provider);
    final bPriority = _providerPriority(b.provider);
    if (aPriority == bPriority) return 0;
    return aPriority.compareTo(bPriority);
  });
  return sorted;
}

int _providerPriority(String provider) {
  final normalized = provider.toLowerCase();
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      if (normalized == 'apple_maps') return 0;
      if (normalized == 'google_maps') return 1;
      return 2;
    case TargetPlatform.android:
      if (normalized == 'google_maps') return 0;
      if (normalized == 'apple_maps') return 1;
      return 2;
    default:
      return 0;
  }
}

IconData _directionProviderIcon(String provider) {
  switch (provider.toLowerCase()) {
    case 'apple_maps':
      return Icons.map_outlined;
    case 'google_maps':
      return Icons.map_rounded;
    case 'yahoo_maps':
      return Icons.directions_transit_rounded;
    default:
      return Icons.near_me_rounded;
  }
}

/// EN: Open external map app first, then fall back to browser if needed.
/// KO: 외부 지도 앱 실행을 우선 시도하고 실패하면 브라우저로 폴백합니다.
Future<void> _launchDirectionsUrl(
  BuildContext context,
  String url, {
  required String providerLabel,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n(
            ko: '길안내 링크를 열 수 없어요',
            en: 'Could not open directions link',
            ja: '経路案内リンクを開けませんでした',
          ),
        ),
      ),
    );
    return;
  }

  try {
    final externalOpened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (externalOpened) return;

    final browserOpened = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (browserOpened) return;
  } catch (_) {
    // EN: Fallback handling below.
    // KO: 아래 폴백 처리로 이어집니다.
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        context.l10n(
          ko: '$providerLabel 길안내를 열지 못했어요',
          en: 'Could not open $providerLabel directions',
          ja: '$providerLabel の経路案内を開けませんでした',
        ),
      ),
    ),
  );
}
