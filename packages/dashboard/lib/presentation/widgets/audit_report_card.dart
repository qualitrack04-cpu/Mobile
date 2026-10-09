import 'package:audit/presentation/widgets/pdf_success_dialog.dart'
    show PdfThumbnailWidget;
import 'package:core_services/core_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kartu satu laporan audit yang sudah selesai.
class AuditReportCard extends StatelessWidget {
  const AuditReportCard({
    super.key,
    required this.report,
    required this.onView,
    required this.onDownload,
  });

  final CompletedAuditReport report;
  final VoidCallback onView;
  final VoidCallback onDownload;

  static const Color _navy = Color(0xFF00104A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail halaman pertama PDF.
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: PdfThumbnailWidget(sessionId: report.sessionId),
                ),
              ),
              Expanded(
                child: Padding(
                  // Atas 26 supaya tidak tertimpa ikon PDF di tengah.
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        report.planTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: onView,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navy,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'View Report',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Ikon PDF di garis pemisah thumbnail dan teks.
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: _navy,
                  size: 24,
                ),
              ),
            ),
          ),
          // Tombol download di pojok kanan atas.
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onDownload,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}