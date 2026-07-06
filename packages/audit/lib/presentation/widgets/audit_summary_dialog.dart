import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuditSummaryDialog extends StatefulWidget {
  final String initialSummary;
  final Function(String summary) onSave; // Callback untuk mengirim data ke parent

  const AuditSummaryDialog({super.key, this.initialSummary = '', required this.onSave});

  @override
  State<AuditSummaryDialog> createState() => _AuditSummaryDialogState();
}

class _AuditSummaryDialogState extends State<AuditSummaryDialog> {
  final TextEditingController _summaryController = TextEditingController();
  int _charCount = 0;
  final int _maxChars = 1000;

  @override
  void initState() {
    super.initState();
    _summaryController.text = widget.initialSummary;
    _charCount = widget.initialSummary.length;
    // Dengarkan setiap ketikan untuk mengupdate jumlah karakter
    _summaryController.addListener(() {
      setState(() {
        _charCount = _summaryController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Agar keyboard tidak menutupi bottom sheet, kita gunakan padding bottom
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + bottomInset, // Tambahan padding saat keyboard muncul
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Drag Handle (Garis kecil di atas)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Judul
            Center(
              child: Text(
                'Complete Audit Details',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F3659), // Warna Navy
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Garis pembatas (Divider tipis)
            Divider(color: Colors.grey[200], thickness: 1),
            const SizedBox(height: 16),

            // 3. Label Audit Summary
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 20, color: Color(0xFF0F3659)),
                const SizedBox(width: 8),
                Text(
                  'AUDIT SUMMARY',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFF0F3659),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Area Teks Input (TextField)
            TextField(
              controller: _summaryController,
              maxLines: 6, // Tinggi kotaknya sekitar 6 baris
              maxLength: _maxChars,
              decoration: InputDecoration(
                hintText: 'Brief overview of finding...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0F3659)),
                ),
                counterText: '', // Sembunyikan counter bawaan TextField karena kita buat sendiri di bawah
              ),
            ),
            
            // 5. Teks penghitung karakter
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '$_charCount/$_maxChars characters',
                  style: GoogleFonts.spaceMono( // Font monospace seperti di desain
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 6. Tombol Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Kirim isi teks ke parent saat tombol ditekan
                  widget.onSave(_summaryController.text);
                  Navigator.pop(context); // Tutup pop-up
                },
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B5C), // Warna Navy gelap sesuai gambar
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}