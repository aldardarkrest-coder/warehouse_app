import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/pending_approval_screen.dart';
import 'screens/home/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
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
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
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
