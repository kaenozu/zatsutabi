import 'package:flutter_test/flutter_test.dart';
import 'package:zatsutabi/app.dart';

void main() {
  testWidgets('renders the decision-first home screen', (tester) async {
    await tester.pumpWidget(const ZatsutabiApp());
    expect(find.text('今日どっか行く？'), findsOneWidget);
    expect(find.text('近場'), findsOneWidget);
    expect(find.text('ちょい遠出'), findsOneWidget);
    expect(find.text('遠出'), findsOneWidget);
  });
}
