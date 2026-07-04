import 'package:aura_drones_ia/app.dart';
import 'package:aura_drones_ia/core/models/auth_user.dart';
import 'package:aura_drones_ia/core/services/auth_service.dart';
import 'package:aura_drones_ia/core/services/location_service.dart';
import 'package:aura_drones_ia/core/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires login before dashboard', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_SignedOutAuthService()),
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

class _SignedOutAuthService implements AuthService {
  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);

  @override
  Future<AuthUser?> reloadCurrentUser() async => null;

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}
