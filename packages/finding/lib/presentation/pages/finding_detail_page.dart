import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:get_it/get_it.dart';

class FindingDetailPage extends StatelessWidget {
  final String findingId;

  const FindingDetailPage({
    super.key,
    required this.findingId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<FindingBloc>()
        ..add(LoadFindingDetail(id: findingId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0D2B55)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Finding Detail',
            style: TextStyle(
              color: Color(0xFF0D2B55),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocBuilder<FindingBloc, FindingState>(
          builder: (context, state) {
            if (state is FindingLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D2B55),
                ),
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
              return _buildDetail(context, state.finding);
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Finding finding) {
    // Mock evidence photos
    final List<String> evidencePhotos = [
      'photo1', 'photo2', 'photo3', 'photo4', 'photo5',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Finding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                finding.clauseRef,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B55),
                ),
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
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

            // Evidence Photos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EVIDENCE PHOTOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Photo 1
                      _buildPhotoThumbnail(
                        index: 0,
                        totalPhotos: evidencePhotos.length,
                      ),
                      const SizedBox(width: 8),
                      // Photo 2
                      _buildPhotoThumbnail(
                        index: 1,
                        totalPhotos: evidencePhotos.length,
                      ),
                      const SizedBox(width: 8),
                      // Photo 3 + counter
                      _buildPhotoThumbnail(
                        index: 2,
                        totalPhotos: evidencePhotos.length,
                        showCounter: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Auditor, Dept, Date
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'AUDITOR',
                    value: 'Marcus Sterling',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.business_outlined,
                    label: 'DEPT',
                    value: 'Quality Control',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'DATE',
                    value:
                        '${finding.foundAt.day} ${_getMonth(finding.foundAt.month)} ${finding.foundAt.year}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail({
    required int index,
    required int totalPhotos,
    bool showCounter = false,
  }) {
    final remainingCount = totalPhotos - 3;

    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: showCounter && remainingCount > 0
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : const Icon(
                  Icons.image_outlined,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}