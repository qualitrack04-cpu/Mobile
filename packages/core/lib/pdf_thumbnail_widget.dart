import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import 'app_colors.dart';

/// Thumbnail halaman pertama sebuah PDF.
///
/// Sumber byte PDF diberikan lewat [loadBytes], sehingga widget ini tidak
/// perlu tahu soal API atau jaringan.
class PdfThumbnailWidget extends StatefulWidget {
  const PdfThumbnailWidget({super.key, required this.loadBytes});

  final Future<List<int>> Function() loadBytes;

  @override
  State<PdfThumbnailWidget> createState() => _PdfThumbnailWidgetState();
}

class _PdfThumbnailWidgetState extends State<PdfThumbnailWidget> {
  PdfDocument? _document;
  PdfPageImage? _pageImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    PdfDocument? document;
    try {
      final bytes = await widget.loadBytes();
      document = await PdfDocument.openData(Uint8List.fromList(bytes));
      final page = await document.getPage(1);

      PdfPageImage? image;
      try {
        // Resolusi kecil supaya hemat memori.
        image = await page.render(
          width: page.width / 3,
          height: page.height / 3,
          format: PdfPageImageFormat.jpeg,
        );
      } finally {
        await page.close();
      }

      if (!mounted) {
        await document.close();
        return;
      }
      setState(() {
        _document = document;
        _pageImage = image;
        _isLoading = false;
      });
    } catch (_) {
      await document?.close();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }
    final image = _pageImage;
    if (_hasError || image == null) {
      return const Center(
        child: Icon(Icons.picture_as_pdf, color: Colors.grey, size: 40),
      );
    }
    return ColoredBox(
      color: Colors.white,
      child: Image.memory(
        image.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        alignment: Alignment.topCenter,
      ),
    );
  }
}