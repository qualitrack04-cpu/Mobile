import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuditFilter extends StatelessWidget {
  final PageController pageController;
  final Function(bool isPriority) onChanged;

  const AuditFilter({
    super.key,
    required this.pageController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double height = (sw * 0.115).clamp(40.0, 50.0);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: sw * 0.05,
        vertical: 16,
      ),
      padding: const EdgeInsets.all(4),
      height: height + 8, // Account for padding
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tabWidth = constraints.maxWidth / 2;

          return AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double page = 0.0;
              if (pageController.hasClients) {
                page = pageController.page ?? pageController.initialPage.toDouble();
              } else {
                page = pageController.initialPage.toDouble();
              }

              return Stack(
                children: [
                  // The sliding background
                  Positioned(
                    left: page * tabWidth,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E97CC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // The tappable text areas
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(false),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: page < 0.5
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                              child: const Text('All'),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(true),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 150),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: page >= 0.5
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                              ),
                              child: const Text('Priority'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}