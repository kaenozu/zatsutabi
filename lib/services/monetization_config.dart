import 'package:flutter/foundation.dart';

/// Compile-time ad configuration. Production IDs are supplied at build time;
/// source-controlled defaults always point at Google's test inventory.
class MonetizationConfig {
  const MonetizationConfig._();

  static const isUsingTestIds = !bool.fromEnvironment(
    'ZATSUTABI_PRODUCTION_ADS',
    defaultValue: false,
  );

  static const androidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );
  static const iosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458009864',
  );
  static const androidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );
  static const iosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  );

  static String get bannerId => defaultTargetPlatform == TargetPlatform.iOS
      ? iosBannerId
      : androidBannerId;
}
