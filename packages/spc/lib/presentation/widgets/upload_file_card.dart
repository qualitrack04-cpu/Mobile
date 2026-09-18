import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spc_card.dart';

/// Area unggah file dengan garis putus-putus.
///
/// Menampilkan dua kondisi: belum ada file (ajakan memilih) dan sudah ada
/// file (nama, ukuran, dan tombol hapus).
class UploadFileCard extends StatelessWidget {
  const UploadFileCard({
    super.key,
    required this.onChooseFile,
    required this.onClearFile,
    this.fileName,
    this.fileSize,
    this.enabled = true,
  });

  final VoidCallback onChooseFile;
  final VoidCallback onClearFile;
  final String? fileName;
  final int? fileSize;
  final bool enabled;

  bool get _hasFile => fileName != null;

  String get _sizeLabel {
    final bytes = fileSize ?? 0;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return SpcCard(
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: _hasFile ? _buildSelected() : _buildEmpty(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        const Icon(
          Icons.upload_file_outlined,
          size: 32,
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        Text(
          'Upload your document',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: enabled ? onChooseFile : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Choose File',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Backend hanya menerima .xlsx dan .xls (lihat allowedExtensions
        // di SpcController.Analyze). CSV sengaja tidak disebut.
        Text(
          'Supported formats: .xlsx, .xls',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }

  Widget _buildSelected() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.action.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.description_outlined,
            size: 20,
            color: AppColors.action,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _sizeLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: enabled ? onClearFile : null,
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.textMuted,
          tooltip: 'Hapus file',
        ),
      ],
    );
  }
}

/// Kotak dengan garis tepi putus-putus.
///
/// Flutter tidak menyediakan border putus-putus bawaan, jadi digambar
/// manual lewat CustomPainter agar tidak perlu dependensi tambahan.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  static const double _radius = 12;
  static const double _dashWidth = 5;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}