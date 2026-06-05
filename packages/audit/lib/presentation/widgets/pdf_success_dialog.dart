import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'close_pdf_preview_dialog.dart';

class PdfSuccessDialog extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onDownload;
  final String reportTitle;

  const PdfSuccessDialog({
    super.key,
    required this.onView,
    required this.onDownload,
    this.reportTitle = 'Monthly Compliance Report',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  // Show the Close PDF Preview Dialog
                  Navigator.pop(context); // Close success dialog
                  showDialog(
                    context: context,
                    builder: (_) => const ClosePdfPreviewDialog(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.grey),
                ),
              ),
            ),
            
            // Checkmark Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF10C675), // Green
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'PDF created successfully',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F3659),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Dummy Thumbnail
            Container(
              width: double.infinity,
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E8F5)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('Your Company', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Text(
                      'Monthly\nCompliance\nReport',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F3659), height: 1.2),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: 20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                    label: Text('View', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003B5C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, color: Color(0xFF003B5C), size: 18),
                    label: Text('Download', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF003B5C))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003B5C)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
