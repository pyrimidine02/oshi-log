/// EN: Runtime registration for licenses of fonts bundled with the app.
/// KO: 앱에 번들된 폰트 라이선스의 런타임 등록입니다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _pretendardLicenseAsset = 'assets/fonts/Pretendard-LICENSE.txt';
bool _isRegistered = false;

/// EN: Makes Pretendard's SIL OFL text available to Flutter's license page.
/// KO: Flutter 라이선스 화면에서 Pretendard SIL OFL 원문을 볼 수 있게 합니다.
void registerGBTFontLicenses() {
  if (_isRegistered) return;
  _isRegistered = true;

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(_pretendardLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Pretendard'], license);
  });
}
