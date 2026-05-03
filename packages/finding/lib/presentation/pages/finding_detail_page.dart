import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:mobile/injector.dart';

class FindingDetailPage extends StatelessWidget {
  final String findingId;

  const FindingDetailPage({
    super.key,
    required this.findingId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FindingBloc>()
        ..add(LoadFindingDetail(id: findingId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Color(0xFF0D2B55)),
          title: const Text(
            'QualiTrack',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Findings Detail',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D2B55),
            ),
          ),
          const SizedBox(height: 24),

          // Detail Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clause Ref sebagai judul
                Text(
                  finding.clauseRef,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2B55),
                  ),
                ),
                const Divider(height: 24),

                // Description
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  finding.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const Divider(height: 24),

                // Info rows
                _buildInfoRow(
                  icon: Icons.category_outlined,
                  label: 'CATEGORY',
                  value: finding.category.toBackendString(),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.info_outline,
                  label: 'STATUS',
                  value: finding.status.toBackendString(),
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
          const SizedBox(height: 24),

          // Link to CAPA Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // Nanti navigate ke CAPA
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2B55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Link to CAPA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
            color: Colors.black54,
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