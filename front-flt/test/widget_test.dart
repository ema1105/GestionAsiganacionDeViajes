import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gav_app/core/error/app_failure.dart';
import 'package:gav_app/core/theme/gav_theme.dart';
import 'package:gav_app/core/widgets/state_views.dart';

Widget _envolver(AsyncValue<List<int>> v) => MaterialApp(
      home: Scaffold(
        body: AsyncValueView<List<int>>(
          value: v,
          isEmpty: (l) => l.isEmpty,
          empty: const EmptyView(mensaje: 'vacío'),
          data: (l) => Text('items: ${l.length}'),
        ),
      ),
    );

void main() {
  setUpAll(() => GavFonts.usarGoogleFonts = false);

  testWidgets('AsyncValueView pinta los 4 estados', (tester) async {
    await tester.pumpWidget(_envolver(const AsyncLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(_envolver(const AsyncData([])));
    expect(find.text('vacío'), findsOneWidget);

    await tester.pumpWidget(_envolver(const AsyncData([1, 2])));
    expect(find.text('items: 2'), findsOneWidget);

    await tester.pumpWidget(_envolver(AsyncError(const NetworkFailure(), StackTrace.empty)));
    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });
}
