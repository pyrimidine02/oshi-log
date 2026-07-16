import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_colors.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';

void main() {
  group('Urban Travel Field Notes palette', () {
    test('exposes the editorial paper, ink, brand blue, and teal anchors', () {
      expect(GBTColors.fieldPaper, const Color(0xFFF7F4EE));
      expect(GBTColors.fieldInk, const Color(0xFF17202A));
      expect(GBTColors.fieldBlue, const Color(0xFF0A66C2));
      expect(GBTColors.fieldTeal, const Color(0xFF2B7773));
      expect(GBTColors.primary, GBTColors.fieldBlue);
      expect(GBTColors.darkPrimary, const Color(0xFF8AB4FF));
      expect(GBTColors.darkPrimaryContainer, const Color(0xFF173A67));
    });

    test('keeps essential foreground and background pairs accessible', () {
      expect(
        GBTColorValidator.hasValidContrast(
          GBTColors.textInverse,
          GBTColors.primary,
        ),
        isTrue,
      );
      expect(
        GBTColorValidator.hasValidContrast(
          GBTColors.textPrimary,
          GBTColors.background,
        ),
        isTrue,
      );
      expect(
        GBTColorValidator.hasValidContrast(
          GBTColors.darkPrimary,
          GBTColors.darkBackground,
        ),
        isTrue,
      );
    });

    test('selects the higher-contrast icon color for bright accents', () {
      expect(
        GBTColorValidator.getContrastingTextColor(GBTColors.accent),
        GBTColors.textPrimary,
      );
      expect(
        GBTColorValidator.getContrastingTextColor(GBTColors.primary),
        GBTColors.textInverse,
      );
    });
  });

  group('route-wide chrome', () {
    test('keeps raw app bars flat on the paper canvas', () {
      expect(
        GBTTheme.light.appBarTheme.backgroundColor,
        GBTColors.appBackground,
      );
      expect(GBTTheme.light.appBarTheme.elevation, 0);
      expect(GBTTheme.light.appBarTheme.scrolledUnderElevation, 0);
      expect(
        GBTTheme.dark.appBarTheme.backgroundColor,
        GBTColors.darkAppBackground,
      );
      expect(GBTTheme.dark.appBarTheme.scrolledUnderElevation, 0);
    });
  });
}
