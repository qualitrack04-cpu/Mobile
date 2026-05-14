import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../domain/entities/audit_entity.dart';
import '../bloc/audit_bloc.dart';
import '../bloc/audit_event.dart';
import '../bloc/audit_state.dart';
import '../widgets/audit_card.dart';
import '../widgets/audit_filter.dart';
import 'audit_form_page.dart';
import 'audit_checklist_page.dart';

class AuditListPage extends StatelessWidget {
  const AuditListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<AuditBloc>()..add(const LoadAudits()),
      child: const _AuditListView(),
    );
  }
}

class _AuditListView extends StatefulWidget {
  const _AuditListView();

  @override
  State<_AuditListView> createState() => _AuditListViewState();
}

class _AuditListViewState extends State<_AuditListView> {
  bool _isPrioritySelected = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ FIX: Simpan list audit terakhir supaya tidak hilang saat state transisi
  // (AuditLoading, AuditDeleted, AuditCreated, dll tidak menghapus list)
  List<AuditEntity> _lastAudits = [];
  bool _isFirstLoad = true;

  List<AuditEntity> _applyFilter(List<AuditEntity> audits, bool isPriority) {
    final filtered = isPriority
        ? audits.where((e) => e.isPriority).toList()
        : List<AuditEntity>.from(audits);

    filtered.sort((a, b) {
      if (a.isFinished == b.isFinished) return 0;
      return a.isFinished ? 1 : -1;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fabSize = (screenWidth * 0.18).clamp(64.0, 88.0);

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Audit Plan',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),

      body: Column(
        children: [
          AuditFilter(
            pageController: _pageController,
            onChanged: (value) {
              setState(() => _isPrioritySelected = value);
              _pageController.animateToPage(
                value ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _isPrioritySelected = index == 1);
              },
              children: [
                _buildBody(isPriority: false),
                _buildBody(isPriority: true),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: SizedBox(
        width: fabSize,
        height: fabSize,
        child: FloatingActionButton(
          backgroundColor: AppColors.primaryLight,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fabSize * 0.25),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuditBloc>(),
                  child: const AuditFormPage(),
                ),
              ),
            );
          },
          child: Icon(
            Icons.add,
            size: fabSize * 0.45,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isPriority}) {
    return BlocConsumer<AuditBloc, AuditState>(
      listener: (context, state) {
        if (state is AuditError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
              ),
            );
        }

        if (state is AuditDeleted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Audit berhasil dihapus'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 2),
              ),
            );
        }

        if (state is AuditCreated) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Audit berhasil dibuat'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 2),
              ),
            );
        }

        if (state is AuditUpdated) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Audit berhasil diperbarui'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
                duration: const Duration(seconds: 2),
              ),
            );
        }

        // Update _lastAudits setiap kali dapat data baru
        if (state is AuditLoaded) {
          _lastAudits = state.audits;
          _isFirstLoad = false;
        }
      },
      builder: (context, state) {
        // ✅ FIX: isLoading hanya true saat PERTAMA kali load (belum punya data)
        // Saat delete/create/update, tetap tampilkan data lama — tidak blank
        final isLoading = _isFirstLoad &&
            (state is AuditLoading || state is AuditInitial);

        // ✅ FIX: Selalu pakai _lastAudits saat transisi state
        // Ini mencegah list kosong saat state AuditDeleted/AuditCreated/dll
        final audits = state is AuditLoaded ? state.audits : _lastAudits;

        // Skeleton placeholder saat first load
        final skeletonList = List.generate(
          4,
          (_) => AuditEntity(
            id: '',
            scheduleId: '',
            title: 'Loading Audit Title Here',
            auditorName: 'Loading Auditor Name',
            isoTemplates: const ['ISO 9001:2015'],
            department: 'Department Name',
            date: DateTime.now(),
            description: '',
            isPriority: false,
            isFinished: false,
          ),
        );

        final displayList = isLoading ? skeletonList : _applyFilter(audits, isPriority);

        // ✅ FIX: Hanya tampilkan "No Audit Data" kalau sudah selesai first load
        // dan benar-benar kosong — bukan saat transisi state
        if (!isLoading && !_isFirstLoad && displayList.isEmpty) {
          return Center(
            child: Text(
              'No Audit Data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            context.read<AuditBloc>().add(const LoadAudits());
            // Tunggu sampai state AuditLoaded atau AuditError
            await context.read<AuditBloc>().stream.firstWhere(
              (s) => s is AuditLoaded || s is AuditError,
            );
          },
          child: Skeletonizer(
            // Skeletonizer hanya aktif saat first load
            enabled: isLoading,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final audit = displayList[index];
                return AuditCard(
                  audit: audit,

                  onEdit: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<AuditBloc>(),
                          child: AuditFormPage(audit: audit),
                        ),
                      ),
                    );
                  },

                  onChecklist: audit.isFinished
                      ? null
                      : () async {
                          await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<AuditBloc>(),
                                child: AuditChecklistPage(audit: audit),
                              ),
                            ),
                          );
                        },

                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Hapus Audit?'),
                        content: Text(
                          'Audit "${audit.title}" akan dihapus secara permanen.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<AuditBloc>().add(DeleteAuditEvent(audit: audit));
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}