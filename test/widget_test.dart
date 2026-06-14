import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mystery_night/src/app.dart';
import 'package:mystery_night/src/state/app_providers.dart';

void main() {
  testWidgets('intro screen renders mystery title',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MysteryNightApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MYSTERY NIGHT'), findsOneWidget);
    expect(find.text('Spiel starten'), findsOneWidget);
  });
}
