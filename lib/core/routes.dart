import 'package:go_router/go_router.dart';
import 'package:realaudiohd/views/Equalizer_screen.dart';
import '../views/home_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String home = '/home';
}

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.welcome,
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      name: 'welcome',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const EqualizerScreen(),
    ),
  ],
);
