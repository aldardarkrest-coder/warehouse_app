import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/home/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
  SyncService.instance.startPeriodicSync();
  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة المخزون',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2D3142),
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2D3142),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
            fontFamily: 'Roboto',
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2D3142), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D3142),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2D3142).withValues(alpha: 0.1),
          selectedIconTheme: const IconThemeData(color: Color(0xFF2D3142)),
          unselectedIconTheme: const IconThemeData(color: Color(0xFF9098B1)),
          selectedLabelTextStyle: const TextStyle(
            color: Color(0xFF2D3142), fontWeight: FontWeight.w600, fontSize: 12,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: Color(0xFF9098B1), fontSize: 12,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2D3142).withValues(alpha: 0.1),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

enum _AuthStatus { unknown, unauthenticated, active, pendingApproval }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService(Supabase.instance.client);
  _AuthStatus _status = _AuthStatus.unknown;

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((_) => _checkAuth());
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (!_authService.isAuthenticated) {
      if (mounted) setState(() => _status = _AuthStatus.unauthenticated);
      return;
    }
    setState(() => _status = _AuthStatus.unknown);
    try {
      final profile = await _authService.getProfile();
      if (!mounted) return;
      if (profile == null) {
        setState(() => _status = _AuthStatus.unauthenticated);
      } else if (profile.isActive) {
        setState(() => _status = _AuthStatus.active);
      } else {
        setState(() => _status = _AuthStatus.pendingApproval);
      }
    } catch (_) {
      if (mounted) setState(() => _status = _AuthStatus.unauthenticated);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _AuthStatus.unauthenticated:
        return LoginScreen(authService: _authService);
      case _AuthStatus.active:
        return MainShell(authService: _authService);
      case _AuthStatus.pendingApproval:
        return PendingApprovalScreen(authService: _authService, onApproved: _checkAuth);
    }
  }
}
