import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/academy/academy_screen.dart';
import '../../features/ai_assistant/ai_chat_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/batteries/batteries_screen.dart';
import '../../features/drones/drones_screen.dart';
import '../../features/flight_planner/flight_planner_screen.dart';
import '../../features/fly_score/fly_score_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/map/map_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/weather/weather_screen.dart';
import '../services/providers.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: '/verify-email',
      builder: (_, _) => const VerifyEmailScreen(),
    ),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    ShellRoute(
      builder: (context, state, child) => AuraShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/weather', builder: (_, _) => const WeatherScreen()),
        GoRoute(path: '/score', builder: (_, _) => const FlyScoreScreen()),
        GoRoute(path: '/ai', builder: (_, _) => const AiChatScreen()),
        GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
        GoRoute(path: '/drones', builder: (_, _) => const DronesScreen()),
        GoRoute(path: '/batteries', builder: (_, _) => const BatteriesScreen()),
        GoRoute(
          path: '/planner',
          builder: (_, _) => const FlightPlannerScreen(),
        ),
        GoRoute(path: '/academy', builder: (_, _) => const AcademyScreen()),
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);

class AuraShell extends ConsumerWidget {
  const AuraShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);
    if (authState.isLoading && user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    if (!user.emailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/verify-email');
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final index = switch (path) {
      '/home' => 0,
      '/weather' || '/score' => 1,
      '/ai' => 2,
      '/planner' || '/drones' || '/batteries' => 3,
      _ => 4,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          final route = switch (value) {
            0 => '/home',
            1 => '/weather',
            2 => '/ai',
            3 => '/planner',
            _ => '/profile',
          };
          context.go(route);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.air_outlined),
            selectedIcon: Icon(Icons.air),
            label: 'Clima',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Aura IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: 'Vuelo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
