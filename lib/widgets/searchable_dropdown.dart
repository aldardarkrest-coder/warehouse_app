import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableDropdownOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  const SearchableDropdownOption({required this.value, required this.label, this.subtitle});
}

class SearchableDropdownFormField<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<SearchableDropdownOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool isLoading;
  final String? errorMessage;

  const SearchableDropdownFormField({
    super.key,
    required this.labelText,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.isLoading = false,
    this.errorMessage,
  });

  String? get _selectedLabel {
    if (value == null) return null;
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
          ),
        ),
        child: Text('جاري التحميل...', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF))),
      );
    }

    if (errorMessage != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          errorText: errorMessage,
          prefixIcon: const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
        ),
        child: const SizedBox.shrink(),
      );
    }

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Icons.arrow_drop_down_rounded),
          suffixIcon: value != null ? IconButton(
            icon: const Icon(Icons.clear_rounded, size: 18),
            onPressed: () => onChanged(null),
          ) : null,
        ),
        child: Text(
          _selectedLabel ?? 'اختر $labelText',
          style: GoogleFonts.cairo(
            color: _selectedLabel != null ? null : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final searchController = TextEditingController();
    var filtered = options;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) {
              return Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'بحث...',
                        hintStyle: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { searchController.clear(); setSheetState(() => filtered = options); })
                            : null,
                      ),
                      onChanged: (v) => setSheetState(() {
                        final q = v.toLowerCase();
                        filtered = options.where((o) =>
                          o.label.toLowerCase().contains(q) ||
                          (o.subtitle?.toLowerCase().contains(q) ?? false)
                        ).toList();
                      }),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('لا توجد نتائج', style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF))))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final o = filtered[i];
                              final selected = o.value == value;
                              return ListTile(
                                selected: selected,
                                selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                leading: Icon(
                                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFFD1D5DB),
                                  size: 20,
                                ),
                                title: Text(o.label, style: GoogleFonts.cairo(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                                subtitle: o.subtitle != null ? Text(o.subtitle!, style: GoogleFonts.cairo(fontSize: 12, color: const Color(0xFF9CA3AF))) : null,
                                onTap: () { onChanged(o.value); Navigator.pop(ctx); },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }
}