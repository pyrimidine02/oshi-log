/// EN: Member dossier page with profile facts and voice-cast records.
/// KO: 프로필 사실과 성우 기록을 담는 멤버 기록 페이지입니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/common/gbt_image.dart';
import '../../../../core/widgets/layout/gbt_page_header.dart';
import '../../../../core/widgets/navigation/gbt_standard_app_bar.dart';
import '../../../projects/application/projects_controller.dart';
import '../../../projects/domain/entities/project_entities.dart';

/// EN: Loads the member contract and preserves routed voice-actor navigation.
/// KO: 멤버 계약을 불러오고 기존 성우 상세 이동을 그대로 유지합니다.
class MemberDetailPage extends ConsumerWidget {
  const MemberDetailPage({
    super.key,
    required this.projectId,
    required this.unitIdentifier,
    required this.memberId,
    this.initialMember,
    this.unit,
  });

  final String projectId;
  final String unitIdentifier;
  final String memberId;
  final UnitMember? initialMember;
  final Unit? unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberState = ref.watch(
      unitMemberDetailControllerProvider((projectId, unitIdentifier, memberId)),
    );
    final member =
        memberState.valueOrNull ??
        initialMember ??
        const UnitMember(id: '', name: '?');
    final resolvedUnit =
        unit ??
        Unit(
          id: unitIdentifier,
          code: unitIdentifier,
          displayName: unitIdentifier,
        );

    return Scaffold(
      appBar: gbtStandardAppBar(context, title: '멤버 기록'),
      body: MemberDossierView(
        member: member,
        unit: resolvedUnit,
        onVoiceActorTap: (actor) => context.goToVoiceActorDetail(
          actor.id,
          projectId: projectId,
          fallbackName: actor.displayName,
        ),
      ),
    );
  }
}

/// EN: Displays a member as an editorial field record, not a wiki card.
/// KO: 멤버를 위키 카드가 아닌 에디토리얼 현장 기록으로 표시합니다.
class MemberDossierView extends StatelessWidget {
  const MemberDossierView({
    super.key,
    required this.member,
    required this.unit,
    required this.onVoiceActorTap,
  });

  final UnitMember member;
  final Unit unit;
  final ValueChanged<VoiceActorRole> onVoiceActorTap;

  @override
  Widget build(BuildContext context) {
    final voiceActors = _voiceActorsFor(member);
    final profileFacts = _profileFactsFor(member);
    final birthdayDays = daysUntilBirthday(member.birthdate);
    final metadata = _memberMetadata(member, unit);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: GBTPageHeader(
              eyebrow: 'MEMBER DOSSIER',
              title: member.name,
              description: metadata.isEmpty ? null : metadata,
            ),
          ),
          if (member.imageUrl?.trim().isNotEmpty == true ||
              member.description?.trim().isNotEmpty == true)
            SliverToBoxAdapter(child: _MemberIntroduction(member: member)),
          if (birthdayDays != null && birthdayDays <= 30)
            SliverToBoxAdapter(child: _BirthdayNote(days: birthdayDays)),
          const SliverToBoxAdapter(
            child: _DossierSectionHeader(
              index: '01',
              eyebrow: 'PROFILE',
              title: '인물 기록',
            ),
          ),
          if (profileFacts.isEmpty)
            const SliverToBoxAdapter(
              child: _InlineEmptyNote(text: '아직 등록된 프로필 메모가 없어요.'),
            )
          else
            SliverList.builder(
              itemCount: profileFacts.length,
              itemBuilder: (context, index) => _ProfileFactRow(
                fact: profileFacts[index],
                isLast: index == profileFacts.length - 1,
              ),
            ),
          if (voiceActors.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: _DossierSectionHeader(
                index: '02',
                eyebrow: 'VOICE CAST',
                title: '성우 기록',
              ),
            ),
            SliverList.builder(
              itemCount: voiceActors.length,
              itemBuilder: (context, index) {
                final actor = voiceActors[index];
                final canOpen = actor.id.trim().isNotEmpty;
                return _VoiceActorIndexRow(
                  index: index + 1,
                  actor: actor,
                  memberName: member.name,
                  onTap: canOpen ? () => onVoiceActorTap(actor) : null,
                );
              },
            ),
          ],
          const SliverToBoxAdapter(
            child: SizedBox(height: GBTSpacing.bottomNavClearance),
          ),
        ],
      ),
    );
  }
}

List<VoiceActorRole> _voiceActorsFor(UnitMember member) {
  if (member.voiceActors.isNotEmpty) {
    return List<VoiceActorRole>.unmodifiable(member.voiceActors);
  }
  final fallbackName = member.voiceActorName?.trim();
  if (fallbackName == null || fallbackName.isEmpty) {
    return const <VoiceActorRole>[];
  }
  return <VoiceActorRole>[VoiceActorRole(id: '', displayName: fallbackName)];
}

String _memberMetadata(UnitMember member, Unit unit) {
  return <String>[
    if (unit.displayName.trim().isNotEmpty) unit.displayName.trim(),
    if (member.characterNameKana?.trim().isNotEmpty == true)
      member.characterNameKana!.trim(),
    if (member.isLeader == true) '리더',
    if (member.isActive == false) '활동 종료',
  ].join('  ·  ');
}

List<_ProfileFact> _profileFactsFor(UnitMember member) {
  return <_ProfileFact>[
    if (member.birthdate?.trim().isNotEmpty == true)
      _ProfileFact(label: '생일', value: member.birthdate!.trim()),
    if (member.hometown?.trim().isNotEmpty == true)
      _ProfileFact(label: '출신', value: member.hometown!.trim()),
    if (member.instrument?.trim().isNotEmpty == true)
      _ProfileFact(label: '담당', value: member.instrument!.trim()),
    if (member.role?.trim().isNotEmpty == true &&
        member.role!.trim() != member.instrument?.trim())
      _ProfileFact(label: '역할', value: member.role!.trim()),
  ];
}

/// EN: Compact rectangular portrait and biography block.
/// KO: 컴팩트한 직사각형 인물 사진과 소개문 블록입니다.
class _MemberIntroduction extends StatelessWidget {
  const _MemberIntroduction({required this.member});

  final UnitMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = member.imageUrl?.trim().isNotEmpty == true;
    final description = member.description?.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.lg,
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            GBTImage(
              imageUrl: member.imageUrl!.trim(),
              width: 96,
              height: 128,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
              fit: BoxFit.cover,
              semanticLabel: '${member.name} 캐릭터 이미지',
            ),
          if (hasImage && description?.isNotEmpty == true)
            const SizedBox(height: GBTSpacing.md),
          if (description?.isNotEmpty == true)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.colorScheme.primary, width: 3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: GBTSpacing.md),
                child: Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.65,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// EN: A time-sensitive birthday field note without a decorative pill.
/// KO: 장식용 필 없이 표시하는 시의성 있는 생일 현장 메모입니다.
class _BirthdayNote extends StatelessWidget {
  const _BirthdayNote({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = days == 0 ? '오늘은 생일이에요.' : '생일까지 $days일 남았어요.';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.md,
        GBTResponsiveSpacing.pageHorizontal(context),
        0,
      ),
      child: Text(
        message,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// EN: Numbered editorial section marker shared within this dossier.
/// KO: 이 기록 화면 안에서 공유하는 번호형 에디토리얼 섹션 표식입니다.
class _DossierSectionHeader extends StatelessWidget {
  const _DossierSectionHeader({
    required this.index,
    required this.eyebrow,
    required this.title,
  });

  final String index;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.xl,
        GBTResponsiveSpacing.pageHorizontal(context),
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant, width: 0.8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: GBTSpacing.xl,
                child: Text(
                  index,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: GBTSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: GBTSpacing.xs2),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileFact {
  const _ProfileFact({required this.label, required this.value});

  final String label;
  final String value;
}

/// EN: Borderless definition row for profile facts.
/// KO: 프로필 사실을 위한 테두리 없는 정의 행입니다.
class _ProfileFactRow extends StatelessWidget {
  const _ProfileFactRow({required this.fact, required this.isLast});

  final _ProfileFact fact;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: GBTSpacing.touchTarget),
      margin: EdgeInsets.symmetric(
        horizontal: GBTResponsiveSpacing.pageHorizontal(context),
      ),
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              fact.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          Expanded(
            child: Text(
              fact.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// EN: Indexed voice-cast record; navigation is enabled only for real IDs.
/// KO: 실제 ID가 있을 때만 이동 가능한 인덱스형 성우 기록입니다.
class _VoiceActorIndexRow extends StatelessWidget {
  const _VoiceActorIndexRow({
    required this.index,
    required this.actor,
    required this.memberName,
    required this.onTap,
  });

  final int index;
  final VoiceActorRole actor;
  final String memberName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = _VoiceActorRowContent(
      index: index,
      actor: actor,
      memberName: memberName,
      canOpen: onTap != null,
    );
    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: '${actor.displayName}. 성우 상세 보기',
      child: ExcludeSemantics(
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _VoiceActorRowContent extends StatelessWidget {
  const _VoiceActorRowContent({
    required this.index,
    required this.actor,
    required this.memberName,
    required this.canOpen,
  });

  final int index;
  final VoiceActorRole actor;
  final String memberName;
  final bool canOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage = actor.profileImageUrl?.trim().isNotEmpty == true;
    final role = actor.roleType?.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      margin: EdgeInsets.symmetric(
        horizontal: GBTResponsiveSpacing.pageHorizontal(context),
      ),
      padding: const EdgeInsets.symmetric(vertical: GBTSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: GBTSpacing.xl,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: GBTSpacing.sm),
          if (hasImage) ...[
            GBTImage(
              imageUrl: actor.profileImageUrl!.trim(),
              width: 48,
              height: 60,
              borderRadius: BorderRadius.circular(GBTSpacing.radiusXs),
              fit: BoxFit.cover,
              semanticLabel: '${actor.displayName} 성우 이미지',
            ),
            const SizedBox(width: GBTSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actor.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: GBTSpacing.xs),
                Text(
                  role?.isNotEmpty == true
                      ? '$memberName  ·  $role'
                      : '$memberName 담당 성우',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (canOpen)
            SizedBox(
              width: GBTSpacing.touchTarget,
              height: GBTSpacing.touchTarget,
              child: Icon(
                Icons.arrow_forward_rounded,
                color: colors.onSurfaceVariant,
                size: GBTSpacing.iconSm,
              ),
            ),
        ],
      ),
    );
  }
}

/// EN: Small inline absence note keeps the document rhythm intact.
/// KO: 작은 인라인 부재 메모로 문서 리듬을 유지합니다.
class _InlineEmptyNote extends StatelessWidget {
  const _InlineEmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.sm,
        GBTResponsiveSpacing.pageHorizontal(context),
        GBTSpacing.md,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
