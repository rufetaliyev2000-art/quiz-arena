import 'package:flutter/material.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/username_setup_screen.dart';
import '../../features/auth/presentation/screens/signup_otp_screen.dart';
import '../../features/auth/presentation/screens/claim_device_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/quiz/presentation/screens/solo_quiz_screen.dart';
import '../../features/battle/presentation/screens/battle_screen.dart';
import '../../features/battle/presentation/screens/bot_battle_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/tournaments/presentation/screens/tournaments_screen.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final s = authState.value;
      final isAuthenticated = s?.status == AuthStatus.authenticated;
      final deviceMismatch = s?.deviceMismatch ?? false;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;

      if (isLoading) return null;

      final publicPaths = ['/splash', '/login'];

      // Authenticated-də cihaz uyğunsuzluğu varsa yalnız /claim-device-ə icazə.
      if (isAuthenticated && deviceMismatch && path != '/claim-device') {
        return '/claim-device';
      }
      // Uyğunsuzluq aradan qalxıbsa amma istifadəçi hələ də /claim-device-dədirsə
      // splash-ə qaytar ki, sıralı yönləndirmə yenidən qiymətləndirilsin.
      if (isAuthenticated && !deviceMismatch && path == '/claim-device') {
        return '/splash';
      }
      if (isAuthenticated && publicPaths.contains(path)) return '/home';
      if (!isAuthenticated && !publicPaths.contains(path)) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup-otp', builder: (_, __) => const SignupOtpScreen()),
      GoRoute(path: '/claim-device', builder: (_, __) => const ClaimDeviceScreen()),
      GoRoute(path: '/setup-username', builder: (_, __) => const UsernameSetupScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/quiz', builder: (_, __) => const SoloQuizScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/battle', builder: (_, __) => const BattleScreen()),
      GoRoute(parentNavigatorKey: _rootNavigatorKey, path: '/bot-battle', builder: (_, __) => const BotBattleScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/tournaments', builder: (_, __) => const TournamentsScreen()),
          GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
          GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );

  // Auth state dəyişdikdə (məs. /users/me 401 → signOut) router-i yenidən
  // qiymətləndir ki, qorunan ekranlardan login-ə yönləndirsin.
  ref.listen(authProvider, (_, __) {
    router.refresh();
  });

  return router;
});

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.location, required this.child});

  static const _tabs = ['/home', '/tournaments', '/shop', '/friends', '/profile'];

  int get _currentIndex {
    final idx = _tabs.indexOf(location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1020),
          border: Border(top: BorderSide(color: Color(0xFF2A2A50), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: (i) => context.go(_tabs[i]),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_rounded), label: l10n.navHome),
            BottomNavigationBarItem(icon: const Icon(Icons.emoji_events_outlined), activeIcon: const Icon(Icons.emoji_events_rounded), label: l10n.navTournaments),
            BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), activeIcon: const Icon(Icons.storefront_rounded), label: l10n.navShop),
            BottomNavigationBarItem(icon: const Icon(Icons.people_outline_rounded), activeIcon: const Icon(Icons.people_rounded), label: l10n.navFriends),
            BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: l10n.navProfile),
          ],
        ),
      ),
    );
  }
}
