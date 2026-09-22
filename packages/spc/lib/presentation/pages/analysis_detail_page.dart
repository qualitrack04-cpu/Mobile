import 'package:core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/spc_analysis.dart';
import '../../domain/usecases/get_analysis_detail.dart';
import '../widgets/spc_section_placeholder.dart';
import 'analysis_result_page.dart';

/// Memuat detail analisis berdasarkan id, lalu menampilkannya dengan
/// [AnalysisResultPage].
class AnalysisDetailPage extends StatefulWidget {
  const AnalysisDetailPage({super.key, required this.analysisId});

  final String analysisId;

  @override
  State<AnalysisDetailPage> createState() => _AnalysisDetailPageState();
}

class _AnalysisDetailPageState extends State<AnalysisDetailPage> {
  late Future<SpcAnalysisResult> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Future disimpan di state, bukan dibuat di build, supaya request tidak
  /// terkirim ulang setiap kali widget di-rebuild.
  void _load() {
    _future = GetIt.I<GetAnalysisDetail>()(widget.analysisId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SpcAnalysisResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AnalysisResultPage(result: snapshot.data!);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: AppColors.primary),
            title: Text(
              'Analysis Result',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: snapshot.hasError
                ? SpcSectionPlaceholder.message(
                    message: snapshot.error
                        .toString()
                        .replaceFirst('Exception: ', ''),
                    icon: Icons.cloud_off_outlined,
                    onRetry: () => setState(_load),
                  )
                : const SpcSectionPlaceholder.loading(),
          ),
        );
      },
    );
  }
}