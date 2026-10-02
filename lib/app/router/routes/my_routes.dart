/// EN: Mypage branch routes (shell index 3).
/// KO: 마이페이지 분기 라우트 (쉘 인덱스 3).
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import '../../../features/my/presentation/travel_passport/travel_passport_page.dart';

List<RouteBase> buildMyRoutes() => [
  GoRoute(
    path: '/mypage',
    name: AppRoutes.mypage,
    builder: (context, state) => const TravelPassportPage(),
  ),
];
