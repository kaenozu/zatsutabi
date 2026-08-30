import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Keeps ad SDK/request startup behind the UMP consent gate.
///
/// Consent failures disable ads for the session but never block the core app.
class AdConsent {
  AdConsent._();

  static const Duration _updateTimeout = Duration(seconds: 5);
  static final ValueNotifier<bool> canRequestAds = ValueNotifier<bool>(false);
  static bool _mobileAdsInitialized = false;

  static Future<void> prepare() async {
    canRequestAds.value = false;
    try {
      final updated = await _requestConsentInfoUpdate();
      if (!updated) return;

      FormError? formError;
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        formError = error;
      });
      if (formError != null) return;

      final allowed = await ConsentInformation.instance.canRequestAds();
      if (!allowed) return;

      if (!_mobileAdsInitialized) {
        await MobileAds.instance.initialize();
        _mobileAdsInitialized = true;
      }
      canRequestAds.value = true;
    } catch (_) {
      canRequestAds.value = false;
    }
  }

  static Future<bool> _requestConsentInfoUpdate() {
    final completer = Completer<bool>();
    void complete(bool value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => complete(true),
      (_) => complete(false),
    );
    return completer.future.timeout(_updateTimeout, onTimeout: () => false);
  }
}
