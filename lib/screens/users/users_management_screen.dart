import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/profile.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class UsersManagementScreen extends StatefulWidget {
  final AuthService authService;

  const UsersManagementScreen({super.key, required this.authService});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Profile>? _users;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final client = Supabase.instance.client;
      final data = await client.from('profiles').select().order('full_name');
      if (mounted) setState(() { _users = data.map((e) => Profile.fromJson(e)).toList(); _isLoading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      final client = Supabase.instance.client;
      await client.from('profiles').update({'role': newRole}).match({'id': userId});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e', style: GoogleFonts.cairo())));
    }
  }

  Future<void> _toggleActive(String userId, bool isActive) async {
    try {
      final client = Supabase.instance.client;
      await client.from('profiles').update({'is_active': !isActive}).match({'id': userId});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _users!.length,
      itemBuilder: (_, i) {
        final user = _users![i];
        final roleColor = user.role == UserRole.admin
            ? const Color(0xFF7C3AED)
            : user.role == UserRole.warehouseManager
                ? const Color(0xFFF59E0B)
                : const Color(0xFF6B7280);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: user.isActive ? const Color(0xFFE5E7EB) : const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.1),
                radius: 22,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.cairo(color: roleColor, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(user.email, style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(user.role.displayName, style: GoogleFonts.cairo(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                onSelected: (role) => _updateRole(user.id, role),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'admin', child: Text('مدير النظام', style: GoogleFonts.cairo())),
                  PopupMenuItem(value: 'warehouse_manager', child: Text('مدير مستودع', style: GoogleFonts.cairo())),
                  PopupMenuItem(value: 'employee', child: Text('موظف', style: GoogleFonts.cairo())),
                ],
              ),
              const SizedBox(width: 8),
              Material(
                color: user.isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _toggleActive(user.id, user.isActive),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      user.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: user.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
