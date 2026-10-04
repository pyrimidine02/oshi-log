/// EN: Centralized action icon set with outline-first defaults.
/// KO: 아웃라인 우선 기본값을 갖는 액션 아이콘 중앙 정의입니다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// EN: Shared icon policy for timeline/community actions.
/// KO: 타임라인/커뮤니티 액션용 공통 아이콘 정책입니다.
class GBTActionIcons {
  GBTActionIcons._();

  // EN: Neutral state uses outlined icon.
  // KO: 기본(중립) 상태는 아웃라인 아이콘을 사용합니다.
  static const IconData comment = Icons.mode_comment_outlined;
  static const IconData like = Icons.favorite_border;
  static const IconData bookmark = Icons.bookmark_border;
  static IconData get share {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return Icons.ios_share_outlined;
    }
    return Icons.share_outlined;
  }

  // EN: Active state may use filled icon to increase state clarity.
  // KO: 활성 상태는 채움 아이콘으로 상태 가시성을 높일 수 있습니다.
  static const IconData likeActive = Icons.favorite;
  static const IconData bookmarkActive = Icons.bookmark;
}
