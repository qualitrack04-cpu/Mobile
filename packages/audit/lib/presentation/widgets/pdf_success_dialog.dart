import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/services/api_service.dart';
import 'package:dio/dio.dart';

class PdfSuccessDialog extends StatelessWidget {
  final VoidCallback onView;
  final VoidCallback onDownload;
  final String reportTitle;
  final String sessionId;

  const PdfSuccessDialog({
    super.key,
    required this.onView,
    required this.onDownload,
    required this.sessionId,
    this.reportTitle = 'Monthly Compliance Report',
  });

  void _showCloseConfirmation(BuildContext pageContext) {
    // Tampilkan dialog konfirmasi DI ATAS PdfSuccessDialog (TIDAK ditutup dulu)
    // Saat "Back" ditekan → hanya dialog konfirmasi yang ditutup
    // → PdfSuccessDialog otomatis kembali terlihat di bawahnya
    showDialog(
      context: pageContext,
      builder: (confirmCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Close PDF Preview?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F3659),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You can find this PDF on your dashboard after closing. The report has been generated successfully.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Go to Dashboard: tutup SEMUA dialog & halaman, kembali ke root
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(confirmCtx, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B5C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Go to Dashboard',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Back: tutup HANYA dialog konfirmasi ini
              // PdfSuccessDialog (View/Download) akan kembali terlihat secara otomatis
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(confirmCtx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF003B5C)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF003B5C)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            // Tombol X — membuka konfirmasi DI ATAS dialog ini
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _showCloseConfirmation(context),
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
                  color: Color(0xFF10C675),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 16),

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

            // Thumbnail
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E8F5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PdfThumbnailWidget(sessionId: sessionId),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol View dan Download
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                    label: Text('View',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
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
                    label: Text('Download',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, color: const Color(0xFF003B5C))),
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

class PdfThumbnailWidget extends StatefulWidget {
  final String sessionId;
  const PdfThumbnailWidget({super.key, required this.sessionId});

  @override
  State<PdfThumbnailWidget> createState() => _PdfThumbnailWidgetState();
}

class _PdfThumbnailWidgetState extends State<PdfThumbnailWidget> {
  PdfDocument? _pdfDoc;
  PdfPageImage? _pageImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPdfThumbnail();
  }

  Future<void> _loadPdfThumbnail() async {
    try {
      final apiService = GetIt.I<ApiService>();
      final response = await apiService.client.get(
        '/api/Pdf/audit-report/${widget.sessionId}',
        options: Options(responseType: ResponseType.bytes),
      );
      
      final document = await PdfDocument.openData(response.data);
      final page = await document.getPage(1);
      
      // Render page at a small thumbnail resolution to save memory
      final pageImage = await page.render(
        width: page.width / 3,
        height: page.height / 3,
        format: PdfPageImageFormat.jpeg,
      );

      if (mounted) {
        setState(() {
          _pdfDoc = document;
          _pageImage = pageImage;
          _isLoading = false;
        });
      }

      await page.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfDoc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24, 
          height: 24, 
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
        )
      );
    }
    if (_hasError || _pageImage == null) {
      return const Center(
        child: Icon(Icons.picture_as_pdf, color: Colors.grey, size: 40),
      );
    }
    return Container(
      color: Colors.white,
      child: Image.memory(
        _pageImage!.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
