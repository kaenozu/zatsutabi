import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_consent.dart';
import '../services/monetization_config.dart';

/// A non-blocking banner: while loading or after failure it occupies no space.
class MonetizationBanner extends StatefulWidget {
  const MonetizationBanner({super.key, this.loadAd = true});

  /// Disabled in widget tests and useful for deterministic previews.
  final bool loadAd;

  @override
  State<MonetizationBanner> createState() => _MonetizationBannerState();
}

class _MonetizationBannerState extends State<MonetizationBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdConsent.canRequestAds.addListener(_handleConsentChanged);
    if (widget.loadAd && AdConsent.canRequestAds.value) _load();
  }

  void _handleConsentChanged() {
    if (!mounted || !widget.loadAd) return;
    if (!AdConsent.canRequestAds.value) {
      final ad = _ad;
      _ad = null;
      ad?.dispose();
      if (_loaded) setState(() => _loaded = false);
      return;
    }
    if (_ad == null && !_loaded) _load();
  }

  void _load() {
    if (!AdConsent.canRequestAds.value || _ad != null) return;
    final ad = BannerAd(
      adUnitId: MonetizationConfig.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !AdConsent.canRequestAds.value) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    AdConsent.canRequestAds.removeListener(_handleConsentChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
