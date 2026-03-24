import 'package:go_router/go_router.dart';
import 'package:meditrack/core/router/route_names.dart';
import 'package:meditrack/features/auth/presentation/pages/login_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: RouteNames.login,
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}
