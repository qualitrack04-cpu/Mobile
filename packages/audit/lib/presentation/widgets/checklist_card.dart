import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import '../../domain/entities/checklist_entity.dart';
import 'package:dotted_border/dotted_border.dart';


class ChecklistCard extends StatelessWidget {
  final ChecklistEntity checklist;
  final VoidCallback? onPass;
  final VoidCallback? onFail;
  final VoidCallback? onAddFinding;
  final VoidCallback? onEditFinding;
  final void Function(bool fromCamera)? onUploadEvidence;
  final VoidCallback? onEditEvidence;

  const ChecklistCard({
    super.key,
    required this.checklist,
    this.onPass,
    this.onFail,
    this.onAddFinding,
    this.onEditFinding,
    this.onUploadEvidence,
    this.onEditEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPass = checklist.isPassed == true;
    final bool isFail = checklist.isPassed == false;
    final double sw = MediaQuery.of(context).size.width;
    final double hMargin = sw * 0.05;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 10),
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFail
              ? AppColors.danger
              : isPass
                  ? AppColors.borderLight
                  : AppColors.borderLight,
          width: isFail || isPass ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isFail),
          const SizedBox(height: 10),
          _buildDescription(),
          const SizedBox(height: 15),
          _buildButtons(context, isPass, isFail),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isFail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            checklist.title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      checklist.description,
      style: GoogleFonts.inter(
        fontSize: 12,
        height: 1.7,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isPass, bool isFail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppColors.borderLight, thickness: 1, height: 24),
        Row(
          children: [
            // Bagian Kiri: Tombol Add Finding / Add Evidence
            // Dibungkus Expanded + Align agar bisa mengecil jika layar sempit (responsif),
            // tapi tidak memaksa tombol menjadi melebar full (sebesar isinya saja)
            // Ini otomatis mendorong tombol Fail/Pass ke ujung kanan!
            if (isFail || isPass)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: isFail
                      ? _buildAddFindingButton()
                      : _buildAddEvidenceButton(context),
                ),
              )
            else
              const Spacer(), // Mengisi ruang kosong jika belum ada yang dipilih

            if (isFail || isPass) const SizedBox(width: 12),

            // Bagian Kanan: Tombol Fail dan Pass
            _buildFailButton(isFail),
            const SizedBox(width: 8),
            _buildPassButton(isPass),
          ],
        ),
      ],
    );
  }

  Widget _buildAddFindingButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 155),
      child: SizedBox(
        height: 46,
        width: double.infinity, // Responsif: mengisi ruang tersedia, maksimal 155
        child: OutlinedButton.icon(
        onPressed: checklist.hasFinding ? onEditFinding : onAddFinding,
        style: OutlinedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppColors.primaryLight),
          backgroundColor: checklist.hasFinding ? AppColors.surface : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Mengikuti gambar
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: Icon(
          checklist.hasFinding ? Icons.edit_outlined : Icons.add,
          size: 16,
          color: checklist.hasFinding ? AppColors.primary : AppColors.surface,
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            checklist.hasFinding ? 'Edit Findings' : 'Add Findings',
            maxLines: 1,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: checklist.hasFinding ? AppColors.primary : AppColors.surface,
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAddEvidenceButton(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 155),
      child: SizedBox(
        height: 46,
        width: double.infinity, // Responsif: mengisi ruang tersedia, maksimal 155
        child: DottedBorder(
          options: const RoundedRectDottedBorderOptions(
            radius: Radius.circular(8),
            color: AppColors.textDisabled,
            strokeWidth: 1.5,
            dashPattern: [6.0, 4.0],
            padding: EdgeInsets.zero,
          ),
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
          child: TextButton.icon(
          onPressed: () {
            if (checklist.hasEvidence) {
              onEditEvidence?.call();
            } else {
              _showImagePicker(context);
            }
          },
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          icon: Icon(
            checklist.hasEvidence ? Icons.edit_outlined : Icons.camera_alt,
            size: 16,
            color: AppColors.textDisabled,
          ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              checklist.hasEvidence ? 'Edit Evidence' : 'Upload Evidence',
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDisabled,
              ),
            ),
          ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPassButton(bool isPass) {
    final bool passDisabled = checklist.hasFinding;
    return SizedBox(
      height: 46,
      width: 72, // Diperkecil sedikit agar responsif
      child: ElevatedButton(
        onPressed: passDisabled ? null : onPass,
        style: ElevatedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
          backgroundColor: isPass ? AppColors.successLight : AppColors.surface,
          foregroundColor: isPass ? AppColors.success : AppColors.textDisabled,
          disabledBackgroundColor: isPass ? AppColors.successLight : AppColors.surface,
          disabledForegroundColor: isPass ? AppColors.success : AppColors.textDisabled,
          side: BorderSide(
            color: isPass ? AppColors.success : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Pass',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFailButton(bool isFail) {
    final bool failDisabled = checklist.hasEvidence;
    return SizedBox(
      height: 46,
      width: 72, // Diperkecil sedikit agar responsif
      child: ElevatedButton(
        onPressed: failDisabled ? null : onFail,
        style: ElevatedButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
          backgroundColor: isFail ? AppColors.dangerLight : AppColors.surface,
          foregroundColor: isFail ? AppColors.danger : AppColors.textDisabled,
          disabledBackgroundColor: isFail ? AppColors.dangerLight : AppColors.surface,
          disabledForegroundColor: isFail ? AppColors.danger : AppColors.textDisabled,
          side: BorderSide(
            color: isFail ? AppColors.danger : AppColors.borderLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          'Fail',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle (sebagai aksen desain)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Text(
                  'Upload Evidence',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Select Image Box
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showCameraGalleryPicker(context); // Tampilkan pilihan kamera/galeri
                  },
                  child: DottedBorder(
                    options: RoundedRectDottedBorderOptions(
                      radius: const Radius.circular(8),
                      color: const Color(0xFFB0C4DE), // Warna garis putus-putus kebiruan
                      strokeWidth: 1.5,
                      dashPattern: const [6.0, 4.0],
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FA), // Background biru sangat muda
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0), // Background icon abu-biru
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select Image',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  void _showCameraGalleryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Select Image Source',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onUploadEvidence?.call(true); // Trigger kamera
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text(
                    'Galeri',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onUploadEvidence?.call(false); // Trigger galeri
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}