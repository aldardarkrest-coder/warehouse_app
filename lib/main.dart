import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final baseTheme = ThemeData();
    final cairo = GoogleFonts.cairoTextTheme(baseTheme.textTheme);

    return MaterialApp(
      title: 'نظام إدارة المخزون',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A56DB),
        brightness: Brightness.light,
        useMaterial3: true,
        textTheme: cairo,
        scaffoldBackgroundColor: const Color(0xFFF0F2F8),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: const Color(0xFF1A56DB),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)),
          labelStyle: GoogleFonts.cairo(color: const Color(0xFF6B7280)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1A56DB).withValues(alpha: 0.1),
          selectedIconTheme: const IconThemeData(color: Color(0xFF1A56DB)),
          unselectedIconTheme: const IconThemeData(color: Color(0xFF9CA3AF)),
          selectedLabelTextStyle: GoogleFonts.cairo(
            color: const Color(0xFF1A56DB), fontWeight: FontWeight.w700, fontSize: 11,
          ),
          unselectedLabelTextStyle: GoogleFonts.cairo(
            color: const Color(0xFF9CA3AF), fontSize: 11,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF1A56DB).withValues(alpha: 0.1),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          },
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

class _AuthGateState extends State<AuthGate> with SingleTickerProviderStateMixin {
  final _authService = AuthService(Supabase.instance.client);
  _AuthStatus _status = _AuthStatus.unknown;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
    _authService.authStateChanges.listen((_) => _checkAuth());
    _checkAuth();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: switch (_status) {
        _AuthStatus.unknown => const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1A56DB)),
                ),
                SizedBox(height: 16),
                Text('جاري التحميل...', style: TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ),
        _AuthStatus.unauthenticated => LoginScreen(authService: _authService),
        _AuthStatus.active => MainShell(authService: _authService),
        _AuthStatus.pendingApproval => PendingApprovalScreen(authService: _authService, onApproved: _checkAuth),
      },
    );
  }
}
