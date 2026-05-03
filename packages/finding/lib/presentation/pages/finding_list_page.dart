import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:finding/presentation/pages/finding_form_page.dart';
import 'package:finding/presentation/pages/finding_detail_page.dart';
import 'package:mobile/injector.dart';

class FindingListPage extends StatelessWidget {
  const FindingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FindingBloc>()..add(const LoadFindings()),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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

            if (state is FindingLoaded) {
              if (state.findings.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada finding',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
                  const Text(
                    'FINDINGS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List Finding
                  ...state.findings.map(
                    (finding) => _FindingCard(finding: finding),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),

        // Tombol tambah finding
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0D2B55),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FindingFormPage(),
              ),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  final Finding finding;

  const _FindingCard({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _getBorderColor(),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    finding.clauseRef,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                ),
                _buildCategoryBadge(),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              finding.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            // Details button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FindingDetailPage(
                          findingId: finding.id,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          color: Color(0xFF0D2B55),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Color(0xFF0D2B55),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return Colors.red;
      case FindingCategory.minorNC:
        return const Color(0xFF3B6FD4);
      case FindingCategory.observation:
        return Colors.orange;
      case FindingCategory.ofi:
        return Colors.green;
    }
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBadgeColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: _getBadgeTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            finding.category.toBackendString(),
            style: TextStyle(
              color: _getBadgeTextColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return const Color(0xFFFFEDED);
      case FindingCategory.minorNC:
        return const Color(0xFFEDF2FF);
      case FindingCategory.observation:
        return const Color(0xFFFFF3ED);
      case FindingCategory.ofi:
        return const Color(0xFFEDFFF3);
    }
  }

  Color _getBadgeTextColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return Colors.red;
      case FindingCategory.minorNC:
        return const Color(0xFF3B6FD4);
      case FindingCategory.observation:
        return Colors.orange;
      case FindingCategory.ofi:
        return Colors.green;
    }
  }
}