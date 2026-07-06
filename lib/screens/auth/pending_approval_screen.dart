import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onApproved;

  const PendingApprovalScreen({super.key, required this.authService, required this.onApproved});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isLoading = false;

  Future<void> _checkAgain() async {
    setState(() => _isLoading = true);
    try {
      final profile = await widget.authService.getProfile();
      if (!mounted) return;
      if (profile != null && profile.isActive) {
        widget.onApproved();
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تفعيل حسابك بعد. يرجى الانتظار.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await widget.authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen(authService: widget.authService)),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'بانتظار الموافقة',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'حسابك قيد المراجعة. سيتم تفعيل حسابك من قبل مدير النظام.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _checkAgain,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('التحقق مرة أخرى'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _logout,
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
