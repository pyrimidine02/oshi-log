import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/places/presentation/widgets/field_map_platform_gate.dart';

void main() {
  test('native map renders only for the active onstage explore surface', () {
    expect(
      shouldRenderFieldMap(isActive: true, isRouteOffstage: false),
      isTrue,
    );
    expect(
      shouldRenderFieldMap(isActive: false, isRouteOffstage: false),
      isFalse,
    );
    expect(
      shouldRenderFieldMap(isActive: true, isRouteOffstage: true),
      isFalse,
    );
  });
}
