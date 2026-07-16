/// EN: Hybrid sponsored slot widget (house campaign + AdMob native ad).
/// KO: 하이브리드 스폰서 슬롯 위젯(하우스 캠페인 + AdMob 네이티브 광고)입니다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/ad_config.dart';
import '../../../../core/theme/gbt_colors.dart';
import '../../../../core/theme/gbt_spacing.dart';
import '../../../../core/widgets/cards/gbt_sponsored_slot_card.dart';
import '../../../../core/providers/core_providers.dart';
import '../../application/ads_controller.dart';
import '../../domain/entities/ad_slot_entities.dart';

/// EN: Fallback content used when backend/network ads are unavailable.
/// KO: 백엔드/네트워크 광고가 없을 때 사용하는 폴백 콘텐츠입니다.
class SponsoredFallbackContent {
  const SponsoredFallbackContent({
    required this.badgeLabel,
    required this.sponsorLabel,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  final String badgeLabel;
  final String sponsorLabel;
  final String title;
  final String description;
  final String ctaLabel;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback onTap;
}

/// EN: Slot rendering strategy for no-decision fallback.
/// KO: 슬롯 결정이 없을 때 사용하는 렌더링 전략입니다.
enum NoDecisionStrategy {
  /// EN: Show house fallback card.
  /// KO: 하우스 폴백 카드를 표시합니다.
  house,

  /// EN: Try AdMob first, then fallback card.
  /// KO: AdMob을 먼저 시도하고 실패 시 폴백 카드를 표시합니다.
  networkThenHouse,
}

/// EN: Rendering strategy when backend explicitly returns deliveryType=none.
/// KO: 백엔드가 deliveryType=none을 명시적으로 반환했을 때의 렌더링 전략입니다.
enum DeliveryNoneStrategy {
  /// EN: Keep slot hidden as instructed by backend.
  /// KO: 백엔드 지시대로 슬롯을 숨깁니다.
  hide,

  /// EN: Render local fallback card to avoid empty UI gaps.
  /// KO: UI 공백 방지를 위해 로컬 폴백 카드를 렌더링합니다.
  fallback,
}

/// EN: Hybrid slot that can render:
/// EN: 1) backend house campaign,
/// EN: 2) backend-selected network ad,
/// EN: 3) local fallback strategy.
/// KO: 다음을 렌더링할 수 있는 하이브리드 슬롯:
/// KO: 1) 백엔드 하우스 캠페인,
/// KO: 2) 백엔드 선택 네트워크 광고,
/// KO: 3) 로컬 폴백 전략.
class HybridSponsoredSlot extends ConsumerStatefulWidget {
  const HybridSponsoredSlot({
    super.key,
    required this.request,
    required this.fallback,
    this.noDecisionStrategy = NoDecisionStrategy.house,
    this.deliveryNoneStrategy = DeliveryNoneStrategy.hide,
    this.margin,
  });

  final AdSlotRequest request;
  final SponsoredFallbackContent fallback;
  final NoDecisionStrategy noDecisionStrategy;
  final DeliveryNoneStrategy deliveryNoneStrategy;
  final EdgeInsetsGeometry? margin;

  @override
  ConsumerState<HybridSponsoredSlot> createState() =>
      _HybridSponsoredSlotState();
}

class _HybridSponsoredSlotState extends ConsumerState<HybridSponsoredSlot> {
  bool _houseImpressionTracked = false;

  @override
  Widget build(BuildContext context) {
    final selectedProjectKey = ref.watch(selectedProjectKeyProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final effectiveRequest = widget.request.projectKey == null
        ? AdSlotRequest(
            placement: widget.request.placement,
            ordinal: widget.request.ordinal,
            projectKey: selectedProjectKey ?? selectedProjectId,
          )
        : widget.request;

    final decisionAsync = ref.watch(adSlotDecisionProvider(effectiveRequest));
    final decision = decisionAsync.valueOrNull;

    if (decision?.deliveryType == AdDeliveryType.none) {
      if (widget.deliveryNoneStrategy == DeliveryNoneStrategy.hide) {
        return const SizedBox.shrink();
      }
      // EN: Use local fallback copy for explicit "none" responses.
      // KO: 명시적 "none" 응답에서는 로컬 폴백 문구를 사용합니다.
      return _buildHouseCard(
        context: context,
        decision: null,
        request: effectiveRequest,
      );
    }

    final networkAdUnitId = _resolveNetworkAdUnitId(decision);
    final shouldPreferNetwork =
        decision?.deliveryType == AdDeliveryType.network ||
        (decision == null &&
            widget.noDecisionStrategy == NoDecisionStrategy.networkThenHouse);

    if (shouldPreferNetwork && networkAdUnitId != null) {
      final decisionId = decision?.decisionId?.trim();
      return _AdMobNativeSlotCard(
        adUnitId: networkAdUnitId,
        fallbackBuilder: () => _buildHouseCard(
          context: context,
          decision: decision,
          request: effectiveRequest,
        ),
        onImpression: () {
          if (decisionId == null || decisionId.isEmpty) {
            return;
          }
          _trackEvent(
            AdEventType.impression,
            request: effectiveRequest,
            decisionId: decisionId,
            campaignId: decision?.campaignId,
          );
        },
        onClick: () {
          if (decisionId == null || decisionId.isEmpty) {
            return;
          }
          _trackEvent(
            AdEventType.click,
            request: effectiveRequest,
            decisionId: decisionId,
            campaignId: decision?.campaignId,
          );
        },
      );
    }

    return _buildHouseCard(
      context: context,
      decision: decision,
      request: effectiveRequest,
    );
  }

  Widget _buildHouseCard({
    required BuildContext context,
    required AdSlotDecision? decision,
    required AdSlotRequest request,
  }) {
    final house = decision?.house;
    final badgeLabel = house?.badgeLabel?.trim().isNotEmpty == true
        ? house!.badgeLabel!.trim()
        : widget.fallback.badgeLabel;
    final sponsorLabel = house?.sponsorLabel?.trim().isNotEmpty == true
        ? house!.sponsorLabel!.trim()
        : widget.fallback.sponsorLabel;
    final title = house?.title?.trim().isNotEmpty == true
        ? house!.title!.trim()
        : widget.fallback.title;
    final description = house?.description?.trim().isNotEmpty == true
        ? house!.description!.trim()
        : widget.fallback.description;
    final ctaLabel = house?.ctaLabel?.trim().isNotEmpty == true
        ? house!.ctaLabel!.trim()
        : widget.fallback.ctaLabel;

    final decisionId = decision?.decisionId?.trim();
    if (!_houseImpressionTracked &&
        decisionId != null &&
        decisionId.isNotEmpty) {
      _houseImpressionTracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _trackEvent(
          AdEventType.impression,
          request: request,
          decisionId: decisionId,
          campaignId: decision?.campaignId,
        );
      });
    }

    return GBTSponsoredSlotCard(
      badgeLabel: badgeLabel,
      sponsorLabel: sponsorLabel,
      title: title,
      description: description,
      ctaLabel: ctaLabel,
      icon: widget.fallback.icon,
      accentColor: widget.fallback.accentColor,
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: GBTSpacing.pageHorizontal,
            vertical: GBTSpacing.xs2,
          ),
      onTap: () {
        if (decisionId != null && decisionId.isNotEmpty) {
          _trackEvent(
            AdEventType.click,
            request: request,
            decisionId: decisionId,
            campaignId: decision?.campaignId,
          );
        }
        _handleHouseTap(context, house);
      },
    );
  }

  void _handleHouseTap(BuildContext context, HouseAdContent? house) {
    final targetPath = house?.targetPath?.trim();
    final targetUrl = house?.targetUrl?.trim();

    if (targetPath != null && targetPath.isNotEmpty) {
      context.go(targetPath);
      return;
    }

    if (targetUrl != null && targetUrl.isNotEmpty) {
      final uri = Uri.tryParse(targetUrl);
      if (uri != null) {
        unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
        return;
      }
    }
    widget.fallback.onTap();
  }

  String? _resolveNetworkAdUnitId(AdSlotDecision? decision) {
    final fromDecision = decision?.network?.adUnitId?.trim();
    if (fromDecision != null && fromDecision.isNotEmpty) {
      return fromDecision;
    }
    return AdConfig.resolveNativeUnitId(widget.request.placement.apiKey);
  }

  void _trackEvent(
    AdEventType eventType, {
    required AdSlotRequest request,
    String? decisionId,
    String? campaignId,
  }) {
    unawaited(
      ref
          .read(adEventTrackerProvider)
          .track(
            eventType: eventType,
            request: request,
            decisionId: decisionId,
            campaignId: campaignId,
          ),
    );
  }
}

class _AdMobNativeSlotCard extends StatefulWidget {
  const _AdMobNativeSlotCard({
    required this.adUnitId,
    required this.fallbackBuilder,
    required this.onImpression,
    required this.onClick,
  });

  final String adUnitId;
  final Widget Function() fallbackBuilder;
  final VoidCallback onImpression;
  final VoidCallback onClick;

  @override
  State<_AdMobNativeSlotCard> createState() => _AdMobNativeSlotCardState();
}

class _AdMobNativeSlotCardState extends State<_AdMobNativeSlotCard> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _impressionTracked = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant _AdMobNativeSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adUnitId != widget.adUnitId) {
      _disposeAd();
      _loadAd();
    }
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  void _loadAd() {
    if (kIsWeb) {
      return;
    }

    MobileAds.instance.initialize();

    final nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        cornerRadius: 14,
        mainBackgroundColor: GBTColors.surface,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
          });
        },
        onAdImpression: (ad) {
          if (_impressionTracked) return;
          _impressionTracked = true;
          widget.onImpression();
        },
        onAdClicked: (ad) {
          widget.onClick();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
          });
        },
      ),
    );
    nativeAd.load();
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _impressionTracked = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return widget.fallbackBuilder();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: GBTSpacing.pageHorizontal,
        vertical: GBTSpacing.xs2,
      ),
      decoration: BoxDecoration(
        // EN: 14px radius intentionally matches GBTSponsoredSlotCard so the
        //     native-ad and house-fallback variants of this slot look like
        //     the same component.
        // KO: 14px 반지름은 네이티브 광고/하우스 폴백 변형이 같은 컴포넌트로
        //     보이도록 GBTSponsoredSlotCard와 의도적으로 맞춘 값입니다.
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? GBTColors.darkBorder.withValues(alpha: 0.55)
              : GBTColors.border.withValues(alpha: 0.55),
          width: 0.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(height: 126, child: AdWidget(ad: _nativeAd!)),
    );
  }
}
