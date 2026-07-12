import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1A56DB)),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: GoogleFonts.cairo(color: const Color(0xFF9CA3AF), fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
