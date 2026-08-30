import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/ad_consent.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZatsutabiApp());
  unawaited(AdConsent.prepare());
}
