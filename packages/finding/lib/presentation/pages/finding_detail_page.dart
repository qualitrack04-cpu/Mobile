import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/data/datasources/finding_remote_datasource.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FindingDetailPage extends StatelessWidget {
  final String findingId;

  const FindingDetailPage({
    super.key,
    required this.findingId,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (_) => GetIt.instance<FindingBloc>()
        ..add(LoadFindingDetail(id: findingId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Finding Detail',
            style: GoogleFonts.inter(
              fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        body: BlocBuilder<FindingBloc, FindingState>(
          builder: (context, state) {
            if (state is FindingLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0D2B55)),
              );
            }
            if (state is FindingError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (state is FindingDetailLoaded) {
              return _FindingDetailBody(finding: state.finding);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _FindingDetailBody extends StatefulWidget {
  final Finding finding;

  const _FindingDetailBody({required this.finding});

  @override
  State<_FindingDetailBody> createState() => _FindingDetailBodyState();
}

class _FindingDetailBodyState extends State<_FindingDetailBody> {
  // ✅ Simpan list evidence sebagai state agar bisa diupdate saat hapus
  List<Map<String, String>> _evidences = [];
  bool _loadingEvidence = true;

  @override
  void initState() {
    super.initState();
    _loadEvidences();
  }

  Future<void> _loadEvidences() async {
    final result = await GetIt.instance<FindingRemoteDatasource>()
        .getEvidences(widget.finding.id);
    if (mounted) {
      setState(() {
        _evidences = result;
        _loadingEvidence = false;
      });
    }
  }

  // ✅ Hapus evidence: panggil API lalu update state lokal
  Future<void> _deleteEvidence(String fileId, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Hapus Evidence?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text('Foto ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await GetIt.instance<FindingRemoteDatasource>().deleteEvidence(fileId);
      if (mounted) {
        setState(() => _evidences.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidence berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finding = widget.finding;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD0DCF0), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Judul
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                finding.clauseRef,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B55),
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── DESCRIPTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A8FAD),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    finding.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── EVIDENCE PHOTOS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'EVIDENCE PHOTOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A8FAD),
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${_evidences.length} foto',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildEvidenceSection(),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // ── Info rows
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  if (finding.auditorName != null &&
                      finding.auditorName!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      label: 'AUDITOR',
                      value: finding.auditorName!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildInfoRow(
                    icon: Icons.business_outlined,
                    label: 'DEPT',
                    value: finding.department,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'DATE',
                    value:
                        '${finding.foundAt.toLocal().day} ${_getMonth(finding.foundAt.toLocal().month)} ${finding.foundAt.toLocal().year}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    if (_loadingEvidence) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
              color: Color(0xFF0D2B55), strokeWidth: 2),
        ),
      );
    }

    if (_evidences.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Text(
          'Belum ada foto evidence',
          style: TextStyle(color: Colors.black38, fontSize: 13),
        ),
      );
    }

    // ✅ Grid foto — 3 per baris, dengan tombol hapus di pojok kanan atas
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _evidences.asMap().entries.map((entry) {
        final index = entry.key;
        final evidence = entry.value;
        final fileId = evidence['id'] ?? '';
        final url = evidence['url'] ?? '';

        return _EvidenceThumbnail(
          url: url,
          fileId: fileId,
          allEvidences: _evidences,
          index: index,
          onDelete: () => _deleteEvidence(fileId, index),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.black45),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D2B55),
          ),
        ),
      ],
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

/// Thumbnail individual dengan tombol hapus
class _EvidenceThumbnail extends StatelessWidget {
  final String url;
  final String fileId;
  final List<Map<String, String>> allEvidences;
  final int index;
  final VoidCallback onDelete;

  const _EvidenceThumbnail({
    required this.url,
    required this.fileId,
    required this.allEvidences,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // ── Foto
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _EvidenceGalleryPage(
                    evidences: allEvidences,
                    initialIndex: index,
                    onDelete: onDelete,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0D2B55)),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.grey[400], size: 28),
                ),
              ),
            ),
          ),

          // ✅ Tombol hapus di pojok kanan atas
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full screen gallery — swipe antar foto + tombol hapus
class _EvidenceGalleryPage extends StatefulWidget {
  final List<Map<String, String>> evidences;
  final int initialIndex;
  final VoidCallback onDelete;

  const _EvidenceGalleryPage({
    required this.evidences,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_EvidenceGalleryPage> createState() => _EvidenceGalleryPageState();
}

class _EvidenceGalleryPageState extends State<_EvidenceGalleryPage> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.evidences.length}',
          style: const TextStyle(color: Colors.white),
        ),
        // ✅ Tombol hapus di AppBar gallery
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Hapus foto ini',
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.evidences.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) {
          final url = widget.evidences[i]['url'] ?? '';
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white54, size: 64),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}