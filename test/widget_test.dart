import 'package:aura_drones_ia/app.dart';
import 'package:aura_drones_ia/core/services/location_service.dart';
import 'package:aura_drones_ia/core/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires login before dashboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(MockLocationService()),
        ],
        child: const AuraDronesApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.textContaining('Iniciar sesion'), findsOneWidget);
    expect(find.text('Crear cuenta nueva'), findsOneWidget);
  });
}
