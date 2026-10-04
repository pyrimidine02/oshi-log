/// EN: Honest home entry states and a stable music entry point.
/// KO: 홈 진입 상태 안내와 고정 음악 진입점입니다.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/platform/router/app_router.dart';
import 'package:oshi_log/design_system/theme/gbt_spacing.dart';

class HomeEntryPrompt extends StatefulWidget {
  const HomeEntryPrompt({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.dismissible = false,
  });
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dismissible;

  @override
  State<HomeEntryPrompt> createState() => _HomeEntryPromptState();
}

class _HomeEntryPromptState extends State<HomeEntryPrompt> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: GBTSpacing.sm),
          Text(widget.message),
          Wrap(
            spacing: GBTSpacing.sm,
            children: [
              if (widget.onAction != null)
                TextButton(
                  onPressed: widget.onAction,
                  child: Text(widget.actionLabel!),
                ),
              if (widget.dismissible)
                TextButton(
                  onPressed: () => setState(() => _dismissed = true),
                  child: Text(context.l10n(ko: '나중에', en: 'Later', ja: 'あとで')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeGuestSections extends StatelessWidget {
  const HomeGuestSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeEntryPrompt(
          title: context.l10n(
            ko: '다음 공연과 성지를 찾아보세요',
            en: 'Find your next show and place',
            ja: '次のライブと聖地を探しましょう',
          ),
          message: context.l10n(
            ko: '로그인하면 관심 대상과 내 기록을 모아볼 수 있어요.',
            en: 'Sign in to keep your interests and records together.',
            ja: 'ログインすると推しや自分の記録をまとめて確認できます。',
          ),
          actionLabel: context.l10n(ko: '로그인', en: 'Sign in', ja: 'ログイン'),
          onAction: () => context.pushNamed(AppRoutes.login),
        ),
        _Shortcut(
          label: context.l10n(ko: '공연 둘러보기', en: 'Browse shows', ja: 'ライブを見る'),
          icon: Icons.event_outlined,
          onTap: () => context.goNamed(AppRoutes.live),
        ),
        _Shortcut(
          label: context.l10n(ko: '성지 지도', en: 'Place map', ja: '聖地マップ'),
          icon: Icons.map_outlined,
          onTap: () => context.goNamed(AppRoutes.map),
        ),
        _Shortcut(
          label: context.l10n(
            ko: '프로젝트 뉴스',
            en: 'Project news',
            ja: 'プロジェクトニュース',
          ),
          icon: Icons.article_outlined,
          onTap: () => context.go('/information'),
        ),
      ],
    );
  }
}

class HomeMusicShortcut extends StatelessWidget {
  const HomeMusicShortcut({super.key});

  @override
  Widget build(BuildContext context) => _Shortcut(
    label: context.l10n(ko: '곡·아티스트', en: 'Songs and artists', ja: '楽曲・アーティスト'),
    icon: Icons.music_note_outlined,
    onTap: () => context.pushNamed(AppRoutes.musicArchive),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: GBTSpacing.touchTarget,
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.arrow_forward_rounded),
    onTap: onTap,
  );
}
