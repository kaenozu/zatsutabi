import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest and Dart ads use the same dart-define inputs', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('dartDefines["ADMOB_ANDROID_APP_ID"]'));
    expect(gradle, contains('dartDefines["ADMOB_ANDROID_BANNER_ID"]'));
    expect(gradle, contains('dartDefines["ZATSUTABI_PRODUCTION_ADS"]'));
    expect(gradle, contains('manifestPlaceholders["admobAppId"] = admobAppId'));
    expect(gradle, isNot(contains('findProperty("admobAppId")')));
    expect(
      gradle,
      contains('Production ad builds must not use Google\'s test AdMob IDs.'),
    );
  });
}
