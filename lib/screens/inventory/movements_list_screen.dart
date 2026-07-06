import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../models/inventory_movement.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class MovementsListScreen extends StatefulWidget {
  final AuthService authService;

  const MovementsListScreen({super.key, required this.authService});

  @override
  State<MovementsListScreen> createState() => _MovementsListScreenState();
}

class _MovementsListScreenState extends State<MovementsListScreen> {
  final _service = InventoryService();
  List<InventoryMovement>? _movements;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try { final data = await _service.getMovements(); if (mounted) setState(() { _movements = data; _isLoading = false; }); }
    catch (e) { if (mounted) setState(() { _error = e.toString(); _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF2D3142),
      child: _movements!.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.swap_horiz_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('لا توجد حركات مخزون', style: TextStyle(color: Colors.grey.shade500)),
          ]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _movements!.length,
              itemBuilder: (_, i) {
                final m = _movements![i];
                final isIn = m.type == MovementType.in_;
                final isOut = m.type == MovementType.out;
                final color = isIn ? const Color(0xFF48BB78) : isOut ? const Color(0xFFE53E3E) : const Color(0xFFED8936);
                final icon = isIn ? Icons.add_rounded : isOut ? Icons.remove_rounded : Icons.swap_horiz_rounded;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8ECF1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.itemName ?? 'غير معروف',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${m.type.displayName} · ${m.warehouseName ?? ""}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                            if (m.createdByName != null && m.createdByName!.isNotEmpty)
                              Text(
                                'بواسطة: ${m.createdByName}',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${m.quantity}',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color),
                          ),
                          if (m.createdAt != null)
                            Text(
                              '${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
