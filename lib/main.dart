import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(
    MobileAds.instance.initialize().then<void>((_) {}, onError: (_) {}),
  );
  runApp(const ZatsutabiApp());
}
