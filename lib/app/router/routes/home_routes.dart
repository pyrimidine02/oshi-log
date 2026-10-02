/// EN: Home branch routes (shell index 0).
/// KO: 홈 분기 라우트 (쉘 인덱스 0).
library;

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show AppRoutes;
import '../../compositions/home/presentation/field_home/field_home_page.dart';

List<RouteBase> buildHomeRoutes() => [
  GoRoute(
    path: '/home',
    name: AppRoutes.home,
    builder: (context, state) => const FieldHomePage(),
  ),
];
