import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';

import 'package:core_services/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/audit_entity.dart';
import '../../data/datasources/checklist_remote_datasource.dart';
import '../widgets/pdf_success_dialog.dart';
import 'audit_checklist_page.dart';
import '../bloc/audit_bloc.dart';
import '../bloc/audit_event.dart';

class AuditReportPreviewPage extends StatefulWidget {
  final AuditEntity audit;
  final String sessionId;

  const AuditReportPreviewPage({
    super.key,
    required this.audit,
    required this.sessionId,
  });

  @override
  State<AuditReportPreviewPage> createState() => _AuditReportPreviewPageState();
}

class _AuditReportPreviewPageState extends State<AuditReportPreviewPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _summary = '';
  List<Map<String, dynamic>> _responses = [];
  List<Map<String, dynamic>> _findings = [];
  Map<String, List<String>> _evidencesMap = {}; // mapping responseId -> list of image URLs

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final dataSource = ChecklistRemoteDatasource(apiService: GetIt.I<ApiService>());
      
      // Fetch concurrently
      final results = await Future.wait([
        dataSource.getAuditSummary(widget.sessionId),
        dataSource.getChecklistResponses(widget.sessionId),
        dataSource.getFindingsBySession(widget.sessionId),
      ]);

      _summary = (results[0] as String?) ?? 'No summary available.';
      _responses = results[1] as List<Map<String, dynamic>>;
      _findings = results[2] as List<Map<String, dynamic>>;

      // Fetch evidences for each response sequentially or concurrently
      for (var response in _responses) {
        final respId = response['id'].toString();
        final bool isPassed = response['isPassed'] == true;
        final String checklistItemId = response['checklistItemId']?.toString() ?? '';

        if (isPassed) {
          final urls = await dataSource.getEvidencesForResponse(respId);
          _evidencesMap[respId] = urls;
        } else {
          try {
            final finding = _findings.firstWhere((f) => f['checklistItemId'].toString() == checklistItemId);
            final findingId = finding['id'].toString();
            final urls = await dataSource.getEvidencesForFinding(findingId);
            _evidencesMap[respId] = urls;
          } catch (e) {
            _evidencesMap[respId] = [];
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8), // Warna background abu-abu terang sesuai desain
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F3659)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AuditChecklistPage(audit: widget.audit),
              ),
            );
          },
        ),
        title: Text(
          'Audit Report Preview',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F3659),
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                  : ListView(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100), // Bottom padding for sticky button
                      children: [
                        _buildSectionTitle('Audit Detail'),
                        _buildAuditDetailCard(),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Audit Summary'),
                        _buildSummaryCard(),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Checklist Result'),
                        ..._responses.map((resp) => _buildChecklistResultCard(resp)),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
          
          // Sticky Button
          if (!_isLoading && _errorMessage.isEmpty)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _buildStickyButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F3659),
        ),
      ),
    );
  }

  Widget _buildAuditDetailCard() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final date = widget.audit.date;
    final dateStr = '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('AUDIT ID', widget.audit.id.substring(0, 8).toUpperCase()),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildDetailRow('DEPARTMENT', widget.audit.department),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildDetailRow('AUDITOR', widget.audit.auditorName),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildDetailRow('AUDIT DATE', dateStr),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildDetailRowWithWidget(
            'STANDARD', 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.audit.isoTemplates.isNotEmpty ? widget.audit.isoTemplates.first : '-',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F3659),
                ),
              ),
            )
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          _buildDetailRowWithWidget(
            'AUDIT STATUS', 
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'Completed',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.green[700]),
                )
              ],
            )
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F3659))),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithWidget(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _summary,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F3659), height: 1.5),
      ),
    );
  }

  Widget _buildChecklistResultCard(Map<String, dynamic> response) {
    final bool isPassed = response['isPassed'] == true;
    final String respId = response['id'].toString();
    final String question = response['question'] ?? 'No Question';
    final String checklistItemId = response['checklistItemId']?.toString() ?? '';
    
    final evidences = _evidencesMap[respId] ?? [];

    // Cari finding yang sesuai dengan checklistItemId jika Fail
    String? auditorNote;
    if (!isPassed) {
      try {
        final finding = _findings.firstWhere((f) => f['checklistItemId'].toString() == checklistItemId);
        auditorNote = finding['description']?.toString();
      } catch (e) {
        // No matching finding found
        auditorNote = 'No detailed note provided.';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Question + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F3659)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPassed ? 'Pass' : 'Fail',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPassed ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Evidences
          if (evidences.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: evidences.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      evidences[idx],
                      width: 240,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(
                        width: 240, height: 160, color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          if (evidences.isNotEmpty) const SizedBox(height: 16),

          // Auditor Note (Only if Fail)
          if (!isPassed) ...[
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'AUDITOR NOTE',
                  style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: const Color(0xFF0F3659), width: 4)),
              ),
              child: Text(
                auditorNote ?? '',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F3659), height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadAndHandlePdf({required bool viewOnly}) async {
    try {
      final apiService = GetIt.I<ApiService>();
      
      // 1. Tampilkan loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 2)),
      );

      // 2. Unduh PDF via API
      final response = await apiService.client.get(
        '/api/Pdf/audit-report/${widget.sessionId}',
        options: Options(responseType: ResponseType.bytes),
      );
      
      // 3. Simpan ke local storage
      final bytes = response.data;
      
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      File file = File('${dir!.path}/audit-report-${widget.sessionId}.pdf');
      int counter = 1;
      while (await file.exists()) {
        file = File('${dir.path}/audit-report-${widget.sessionId} ($counter).pdf');
        counter++;
      }

      await file.writeAsBytes(bytes);

      // 4. TANDAI SESI SELESAI SECARA PERMANEN KARENA PDF SUDAH DIGENERATE
      try {
        final datasource = GetIt.instance<ChecklistRemoteDatasource>();
        await datasource.markSessionComplete(widget.sessionId);
        
        // Hapus session key agar audit ini tidak bisa dilanjutkan/direview lagi
        final prefs = await SharedPreferences.getInstance();
        final sessionKey = 'audit_session_${widget.audit.scheduleId}';
        await prefs.remove(sessionKey);
        await prefs.remove('${sessionKey}_state');
        
        // Tandai audit finished di Bloc agar List terupdate
        if (mounted) {
          context.read<AuditBloc>().add(
            MarkAuditFinishedEvent(audit: widget.audit, isFinished: true)
          );
        }
      } catch (e) {
        // Abaikan error jika gagal tandai selesai, minimal PDF sudah terdownload
      }

      if (mounted) {
        if (viewOnly) {
          // Buka dengan aplikasi eksternal
          OpenFilex.open(file.path);
        } else {
          // Hanya notifikasi sukses download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF downloaded to ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStickyButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          // 1. Tampilkan dialog sukses
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => PdfSuccessDialog(
              onView: () {
                _downloadAndHandlePdf(viewOnly: true);
              },
              onDownload: () {
                _downloadAndHandlePdf(viewOnly: false);
              },
            ),
          );
        },
        icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
        label: Text(
          'Create PDF',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003B5C), // Navy blue
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
