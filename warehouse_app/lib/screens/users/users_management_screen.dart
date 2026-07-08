import 'package:flutter/material.dart';
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
            ? const Color(0xFF805AD5)
            : user.role == UserRole.warehouseManager
                ? const Color(0xFF2D3142)
                : const Color(0xFF718096);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: user.isActive ? const Color(0xFFE8ECF1) : const Color(0xFFE53E3E).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.1),
                radius: 22,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                  child: Text(user.role.displayName, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                onSelected: (role) => _updateRole(user.id, role),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'admin', child: Text('مدير النظام')),
                  const PopupMenuItem(value: 'warehouse_manager', child: Text('مدير مستودع')),
                  const PopupMenuItem(value: 'employee', child: Text('موظف')),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleActive(user.id, user.isActive),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: user.isActive ? const Color(0xFF48BB78).withValues(alpha: 0.1) : const Color(0xFFE53E3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    user.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: user.isActive ? const Color(0xFF48BB78) : const Color(0xFFE53E3E),
                    size: 20,
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
