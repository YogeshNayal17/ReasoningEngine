import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reason_ai/app.dart';

void main() {
  testWidgets('App boots and shows the home screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ReasonAiApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reason AI'), findsWidgets);
  });
}
