import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oshi_log/app/router/auth_guard.dart';
import 'package:oshi_log/app/router/routes/legacy_alias_routes.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';

void main() {
  test('legacy links preserve repeated query, unicode IDs and fragments', () {
    final input = Uri(
      pathSegments: ['', 'information', 'units', 'バンド / A', 'members', '声優'],
      queryParameters: {
        'projectId': 'p/q',
        'tag': ['a', 'b'],
      },
      fragment: 'credits',
    );
    final output = Uri.parse(legacyRouteDestination(input)!);
    expect(output.pathSegments, [
      'live',
      'artists',
      'バンド / A',
      'members',
      '声優',
    ]);
    expect(output.queryParametersAll, input.queryParametersAll);
    expect(output.fragment, 'credits');
  });

  test('legacy tab parsing clamps and consumes only tab', () {
    for (final entry in {
      '-1': '/map',
      'bad': '/map',
      '1': '/live',
      '2': '/mypage/records',
      '99': '/map',
    }.entries) {
      final uri = Uri.parse(
        legacyRouteDestination(Uri.parse('/explore?tab=${entry.key}&q=x#end'))!,
      );
      expect(uri.path, entry.value);
      expect(uri.queryParameters['q'], 'x');
      expect(uri.queryParameters.containsKey('tab'), isFalse);
      expect(uri.fragment, 'end');
    }
    expect(
      Uri.parse(
        legacyRouteDestination(Uri.parse('/explore?tab=99'))!,
      ).queryParameters['section'],
      'collections',
    );
    expect(legacyRouteDestination(Uri.parse('/information/unknown')), isNull);
  });

  testWidgets(
    'guest old links normalize before auth and protected links retain full URI',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/explore/places/spot?x=1#notice',
        redirect: authRedirect(AuthState.unauthenticated),
        routes: [
          ...buildLegacyAliasRoutes(),
          for (final path in [
            '/map/places/:placeId',
            '/mypage/records',
            '/login',
          ])
            GoRoute(path: path, builder: (_, _) => const SizedBox()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/map/places/spot?x=1#notice',
      );
      router.go('/explore?tab=2&filter=all#last');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['redirect'],
        '/mypage/records?filter=all#last',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
