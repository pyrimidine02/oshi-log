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
import '../../application/ads_runtime_service.dart';
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

/// EN: Accept only an app-relative route supplied by a house campaign.
///     URI schemes and authorities are rejected so backend content cannot
///     turn an in-app navigation action into an external redirect.
/// KO: 하우스 캠페인이 제공한 앱 상대 경로만 허용합니다. 백엔드 콘텐츠가
///     인앱 이동을 외부 리디렉션으로 바꾸지 못하도록 URI 스킴과 authority를
///     거부합니다.
String? safeHouseTargetPath(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty || value.contains(r'\')) return null;

  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (uri.path.isEmpty || !uri.path.startsWith('/')) return null;
  return value;
}

/// EN: Accept only an HTTPS external URL without embedded credentials.
/// KO: 자격 증명을 포함하지 않은 HTTPS 외부 URL만 허용합니다.
Uri? safeHouseTargetUri(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme.toLowerCase() != 'https') return null;
  if (uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
  return uri;
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
  String? _houseImpressionIdentity;

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
    final adsRuntime = ref.watch(adsRuntimeServiceProvider);

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
        key: ValueKey(
          'admob-${effectiveRequest.placement.apiKey}-'
          '${effectiveRequest.ordinal}-${effectiveRequest.projectKey}-'
          '${decision?.decisionId}-${decision?.campaignId}-$networkAdUnitId',
        ),
        adUnitId: networkAdUnitId,
        identity: _networkIdentity(effectiveRequest, decision, networkAdUnitId),
        runtimeService: adsRuntime,
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
    final impressionIdentity = _houseIdentity(request, decision);
    if (_houseImpressionIdentity != impressionIdentity &&
        decisionId != null &&
        decisionId.isNotEmpty) {
      _houseImpressionIdentity = impressionIdentity;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _houseImpressionIdentity != impressionIdentity) return;
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
        unawaited(_handleHouseTap(context, house));
      },
    );
  }

  Future<void> _handleHouseTap(
    BuildContext context,
    HouseAdContent? house,
  ) async {
    final targetPath = house?.targetPath?.trim();
    final targetUrl = house?.targetUrl?.trim();

    final safePath = safeHouseTargetPath(targetPath);
    if (safePath != null) {
      try {
        context.go(safePath);
      } catch (_) {
        widget.fallback.onTap();
      }
      return;
    }

    final safeUri = safeHouseTargetUri(targetUrl);
    if (safeUri != null) {
      try {
        final launched = await launchUrl(
          safeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {
        // EN: Fall through to the local action when an external launch fails.
        // KO: 외부 실행이 실패하면 로컬 액션으로 폴백합니다.
      }
    }
    widget.fallback.onTap();
  }

  String? _resolveNetworkAdUnitId(AdSlotDecision? decision) {
    final fromDecision = decision?.network?.adUnitId?.trim();
    return AdConfig.resolveNativeUnitId(
      widget.request.placement.apiKey,
      serverUnitId: fromDecision,
      serverNetworkIsAdMob:
          decision == null ||
          decision.network?.networkType == AdNetworkType.admob,
    );
  }

  String _houseIdentity(AdSlotRequest request, AdSlotDecision? decision) {
    return '${request.placement.apiKey}:${request.ordinal}:'
        '${request.projectKey}:${decision?.decisionId}:${decision?.campaignId}';
  }

  String _networkIdentity(
    AdSlotRequest request,
    AdSlotDecision? decision,
    String adUnitId,
  ) {
    return '${_houseIdentity(request, decision)}:$adUnitId';
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
    super.key,
    required this.adUnitId,
    required this.identity,
    required this.runtimeService,
    required this.fallbackBuilder,
    required this.onImpression,
    required this.onClick,
  });

  final String adUnitId;
  final String identity;
  final AdsRuntimeService runtimeService;
  final Widget Function() fallbackBuilder;
  final VoidCallback onImpression;
  final VoidCallback onClick;

  @override
  State<_AdMobNativeSlotCard> createState() => _AdMobNativeSlotCardState();
}

class _AdMobNativeSlotCardState extends State<_AdMobNativeSlotCard> {
  NativeAd? _nativeAd;
  NativeAd? _loadingAd;
  bool _isLoaded = false;
  bool _impressionTracked = false;
  int _loadGeneration = 0;
  StreamSubscription<AdsReadiness>? _readinessSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToReadiness();
    _loadAd();
  }

  @override
  void didUpdateWidget(covariant _AdMobNativeSlotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serviceChanged = oldWidget.runtimeService != widget.runtimeService;
    if (serviceChanged) {
      _readinessSubscription?.cancel();
      _subscribeToReadiness();
    }
    if (serviceChanged || oldWidget.identity != widget.identity) {
      _disposeAd();
      _loadAd();
    }
  }

  @override
  void dispose() {
    _readinessSubscription?.cancel();
    _disposeAd();
    super.dispose();
  }

  void _subscribeToReadiness() {
    _readinessSubscription = widget.runtimeService.readinessChanges.listen((
      readiness,
    ) {
      if (!mounted) return;
      if (readiness != AdsReadiness.ready) {
        final hadAd = _nativeAd != null || _loadingAd != null || _isLoaded;
        _disposeAd();
        if (hadAd) setState(() {});
        return;
      }
      if (_nativeAd == null && _loadingAd == null) {
        _loadAd();
      }
    });
  }

  Future<void> _loadAd() async {
    if (kIsWeb) {
      return;
    }

    final generation = ++_loadGeneration;
    final readiness = await widget.runtimeService.ensureReady();
    if (!mounted ||
        generation != _loadGeneration ||
        readiness != AdsReadiness.ready) {
      return;
    }

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
          if (!mounted || generation != _loadGeneration) {
            ad.dispose();
            return;
          }
          _loadingAd = null;
          if (ad is! NativeAd) {
            ad.dispose();
            return;
          }
          setState(() {
            _nativeAd = ad;
            _isLoaded = true;
          });
        },
        onAdImpression: (ad) {
          if (!mounted || generation != _loadGeneration) return;
          if (_impressionTracked) return;
          _impressionTracked = true;
          widget.onImpression();
        },
        onAdClicked: (ad) {
          if (!mounted || generation != _loadGeneration) return;
          widget.onClick();
        },
        onAdFailedToLoad: (ad, error) {
          if (identical(_loadingAd, ad)) _loadingAd = null;
          ad.dispose();
          if (!mounted || generation != _loadGeneration) return;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
          });
        },
      ),
    );
    _loadingAd = nativeAd;
    try {
      await nativeAd.load();
    } catch (_) {
      if (!identical(_loadingAd, nativeAd)) return;
      _loadingAd = null;
      nativeAd.dispose();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _nativeAd = null;
        _isLoaded = false;
      });
    }
  }

  void _disposeAd() {
    _loadGeneration++;
    _loadingAd?.dispose();
    _loadingAd = null;
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
