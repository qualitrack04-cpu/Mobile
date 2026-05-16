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

    return BlocProvider.value(
      value: GetIt.instance<FindingBloc>()
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
            'Findings Detail',
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
                    value: finding.department == 'Produksi' ? 'Production' : finding.department,
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

    // ✅ Row dengan max 3 gambar, gambar ke-3 ada +N jika lebih
    final shown = _evidences.take(3).toList();
    final remaining = _evidences.length - 3;

    return Row(
      children: [
        for (int i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _EvidenceThumbnail(
              url: shown[i]['url'] ?? '',
              fileId: shown[i]['id'] ?? '',
              allEvidences: _evidences,
              index: i,
              showCounter: i == 2 && remaining > 0,
              remaining: remaining,
            ),
          ),
        ],
        for (int i = shown.length; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          const Expanded(child: SizedBox.shrink()),
        ],
      ],
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
  final bool showCounter;
  final int remaining;

  const _EvidenceThumbnail({
    required this.url,
    required this.fileId,
    required this.allEvidences,
    required this.index,
    this.showCounter = false,
    this.remaining = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
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
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
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
          
          // ✅ Counter overlay "+N" di foto ke-3 jika ada lebih
          if (showCounter && remaining > 0)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _EvidenceGalleryPage(
                        evidences: allEvidences,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

  const _EvidenceGalleryPage({
    required this.evidences,
    required this.initialIndex,
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