/// EN: `/mypage` root (PR9 IA): routes to the guest intro when unauthenticated
/// EN: so the branch stays public without issuing protected calls, and to
/// EN: `TravelPassportPage` otherwise.
/// KO: `/mypage` 루트(PR9 IA): 비로그인 상태에서는 보호 호출 없이 분기를
/// KO: 공개 상태로 유지하기 위해 게스트 소개로, 그 외에는
/// KO: `TravelPassportPage`로 라우팅합니다.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'mypage_guest_intro_page.dart';
import 'travel_passport_page.dart';

class MypageRootPage extends ConsumerWidget {
  const MypageRootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    if (authState != AuthState.authenticated) {
      return const MypageGuestIntroPage();
    }
    return const TravelPassportPage();
  }
}
