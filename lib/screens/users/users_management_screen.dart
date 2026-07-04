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
      await client.from('profiles').update({'role': newRole}).eq('id', userId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleActive(String userId, bool isActive) async {
    try {
      final client = Supabase.instance.client;
      await client.from('profiles').update({'is_active': !isActive}).eq('id', userId);
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
      padding: const EdgeInsets.all(8), itemCount: _users!.length,
      itemBuilder: (_, i) {
        final user = _users![i];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?')),
          title: Text(user.fullName),
          subtitle: Text('${user.email} | ${user.role.displayName}'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            PopupMenuButton<String>(
              child: Chip(label: Text(user.role.displayName, style: const TextStyle(fontSize: 12))),
              onSelected: (role) => _updateRole(user.id, role),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'admin', child: Text('مدير النظام')),
                const PopupMenuItem(value: 'warehouse_manager', child: Text('مدير مستودع')),
                const PopupMenuItem(value: 'employee', child: Text('موظف')),
              ],
            ),
            IconButton(
              icon: Icon(user.isActive ? Icons.check_circle : Icons.cancel, color: user.isActive ? Colors.green : Colors.red),
              onPressed: () => _toggleActive(user.id, user.isActive),
            ),
          ]),
        ));
      },
    );
  }
}
