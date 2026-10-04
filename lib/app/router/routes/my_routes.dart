/// EN: Mypage branch routes (shell index 4).
/// EN: PR9 IA: `/mypage` is public (guest intro); `/mypage/records` is the
/// EN: canonical home for the old `/explore?tab=2` visit ledger destination.
/// KO: 마이페이지 분기 라우트 (쉘 인덱스 4).
/// KO: PR9 IA: `/mypage`는 공개(게스트 소개)이며, `/mypage/records`는 기존
/// KO: `/explore?tab=2` 방문 원장 목적지의 canonical 경로입니다.
library;

import 'package:go_router/go_router.dart';

import '../../../platform/router/app_router.dart' show AppRoutes;
import '../../compositions/today/presentation/today_page.dart';
import '../../compositions/trips/presentation/private_trips_page.dart';
import '../../compositions/my/presentation/travel_passport/mypage_root_page.dart';
import '../../compositions/visits/presentation/field_visit_ledger/field_visit_ledger_page.dart';

List<RouteBase> buildMyRoutes() => [
  GoRoute(
    path: '/mypage',
    name: AppRoutes.mypage,
    builder: (context, state) => const MypageRootPage(),
    routes: [
      GoRoute(
        path: 'today',
        name: AppRoutes.today,
        builder: (context, state) => const TodayPage(),
      ),
      GoRoute(
        path: 'trips',
        name: AppRoutes.privateTrips,
        builder: (context, state) => const PrivateTripsPage(),
      ),
      GoRoute(
        path: 'records',
        name: AppRoutes.visitRecords,
        builder: (context, state) => const FieldVisitLedgerPage(),
      ),
    ],
  ),
];
