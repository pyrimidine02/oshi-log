import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/features/profile_banner/presentation/banner_picker_layout.dart';

void main() {
  group('resolveBannerPickerLayout', () {
    test('uses one readable column on compact phones', () {
      expect(resolveBannerPickerLayout(320).columns, 1);
    });

    test('uses two columns on regular phones', () {
      expect(resolveBannerPickerLayout(390).columns, 2);
    });

    test('caps the catalog at three columns on wide screens', () {
      expect(resolveBannerPickerLayout(900).columns, 3);
    });
  });
}
