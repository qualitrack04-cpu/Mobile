import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finding/domain/entities/finding.dart';
import 'package:finding/domain/entities/finding_severity.dart';
import 'package:finding/presentation/bloc/finding_bloc.dart';
import 'package:finding/presentation/bloc/finding_event.dart';
import 'package:finding/presentation/bloc/finding_state.dart';
import 'package:finding/presentation/pages/finding_form_page.dart';
import 'package:finding/presentation/pages/finding_detail_page.dart';
import 'package:finding/presentation/pages/finding_edit_page.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FindingListPage extends StatelessWidget {
  const FindingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<FindingBloc>()..add(const LoadFindings()),
      child: const _FindingListView(),
    );
  }
}

class _FindingListView extends StatefulWidget {
  const _FindingListView();

  @override
  State<_FindingListView> createState() => _FindingListViewState();
}

class _FindingListViewState extends State<_FindingListView> {
  List<Finding> _lastFindings = [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Text(
                'Findings',
                style: GoogleFonts.inter(
                  fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),

            body: BlocConsumer<FindingBloc, FindingState>(
              listener: (context, state) {
                if (state is FindingLoaded) {
                  _lastFindings = state.findings;
                }
              },
              builder: (context, state) {
                final isLoading = state is FindingLoading || state is FindingInitial;
                final findings = state is FindingLoaded ? state.findings : _lastFindings;

                if (state is FindingError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                // Skeleton placeholder saat first load
                final skeletonList = List.generate(
                  4,
                  (_) => Finding(
                    id: '',
                    category: FindingCategory.majorNC,
                    description: 'Loading Description Here',
                    clauseRef: '-',
                    foundAt: DateTime.now(),
                    status: FindingStatus.open,
                    department: 'Department Name',
                  ),
                );

                final displayList = isLoading ? skeletonList : findings;

                // Urutkan berdasarkan kategori
                final sortedFindings = List.of(displayList)..sort((a, b) {
                  return a.category.index.compareTo(b.category.index);
                });

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        context.read<FindingBloc>().add(const LoadFindings());
                        await Future.delayed(const Duration(milliseconds: 800));
                      },
                      child: Skeletonizer(
                        enabled: isLoading,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          children: [
                            if (!isLoading && sortedFindings.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 100),
                                  child: Text(
                                    'Belum ada finding',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...sortedFindings.map(
                                (finding) => _FindingCard(finding: finding),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // FAB tambah finding baru
                      // FAB tambah finding baru
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Builder(
                          builder: (context) {
                            final screenWidth =
                                MediaQuery.of(context).size.width;

                            // ukuran FAB dinamis seperti AuditListPage
                            final fabSize = (screenWidth * 0.18).clamp(
                              64.0,
                              88.0,
                            );

                            return SizedBox(
                              width: fabSize,
                              height: fabSize,
                              child: FloatingActionButton(
                                backgroundColor: AppColors.primaryLight,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    fabSize * 0.25,
                                  ),
                                ),
                                onPressed: () async {
                                  final bloc = context.read<FindingBloc>();

                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => BlocProvider.value(
                                            value: bloc,
                                            child: const FindingFormPage(),
                                          ),
                                    ),
                                  );

                                  // FindingFormPage mengembalikan Finding object saat berhasil
                                  if (result != null && context.mounted) {
                                    bloc.add(const LoadFindings());
                                  }
                                },
                                child: Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: fabSize * 0.45,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
              },
            ),
          );
  }
}

class _FindingCard extends StatelessWidget {
  final Finding finding;

  const _FindingCard({required this.finding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FindingDetailPage(findingId: finding.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getCardBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: _getBorderColor(), width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: title + badge category
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      finding.clauseRef,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D2B55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryBadge(),
                ],
              ),
              const SizedBox(height: 8),

              // description
              Text(
                finding.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              // Baris bawah: tombol Edit (kiri) + Details (kanan)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ Tombol Edit — dengan frame yang jelas
                  GestureDetector(
                    onTap: () async {
                      final bloc = context.read<FindingBloc>();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => BlocProvider.value(
                                value: bloc,
                                child: FindingEditPage(finding: finding),
                              ),
                        ),
                      );
                      // FindingEditPage mengembalikan Finding object saat berhasil
                      if (result != null && context.mounted) {
                        bloc.add(const LoadFindings());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EEF3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFCDD5DE),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Details (tetap seperti semula)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FindingDetailPage(findingId: finding.id),
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
      ),
    );
  }

  Color _getCardBackgroundColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return const Color(0xFFFFF0F0);
      case FindingCategory.minorNC:
        return Colors.white;
      case FindingCategory.ofi:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return Colors.red;
      case FindingCategory.minorNC:
        return Colors.orange;
      case FindingCategory.ofi:
        return const Color(0xFF3B6FD4);
    }
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBadgeColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getBadgeLabel(),
        style: TextStyle(
          color: _getBadgeTextColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getBadgeLabel() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return 'Major NC';
      case FindingCategory.minorNC:
        return 'Minor NC';
      case FindingCategory.ofi:
        return 'OFI';
    }
  }

  Color _getBadgeColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return const Color(0xFFFFDDDD);
      case FindingCategory.minorNC:
        return const Color(0xFFFFEDD5);
      case FindingCategory.ofi:
        return const Color(0xFFDDE8FF);
    }
  }

  Color _getBadgeTextColor() {
    switch (finding.category) {
      case FindingCategory.majorNC:
        return Colors.red;
      case FindingCategory.minorNC:
        return Colors.orange;
      case FindingCategory.ofi:
        return const Color(0xFF3B6FD4);
    }
  }
}