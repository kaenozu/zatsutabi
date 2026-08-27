import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zatsutabi/services/monetization_config.dart';
import 'package:zatsutabi/ui/monetization_banner.dart';

void main() {
  test('development configuration uses official test IDs', () {
    expect(MonetizationConfig.isUsingTestIds, isTrue);
    expect(
      MonetizationConfig.androidAppId,
      'ca-app-pub-3940256099942544~3347511713',
    );
    expect(
      MonetizationConfig.iosAppId,
      'ca-app-pub-3940256099942544~1458009864',
    );
  });

  testWidgets('banner fallback keeps the layout usable before an ad loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MonetizationBanner(loadAd: false)),
    );

    expect(find.byType(MonetizationBanner), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
