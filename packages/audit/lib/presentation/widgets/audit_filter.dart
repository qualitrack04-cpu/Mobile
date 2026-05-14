import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuditFilter extends StatelessWidget {
  final bool isPrioritySelected;
  final Function(bool isPriority) onChanged;

  const AuditFilter({
    super.key,
    required this.isPrioritySelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: sw * 0.05,
        vertical: 16,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          /// ALL BUTTON
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: (sw * 0.115).clamp(40.0, 50.0),
                decoration: BoxDecoration(
                  color: !isPrioritySelected
                      ? const Color(0xFF6E97CC)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'All',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: !isPrioritySelected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),

          /// PRIORITY BUTTON
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: (sw * 0.115).clamp(40.0, 50.0),
                decoration: BoxDecoration(
                  color: isPrioritySelected
                      ? const Color(0xFF6E97CC)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Priority',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPrioritySelected
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}