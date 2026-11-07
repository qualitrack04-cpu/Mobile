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
import 'package:core_services/core_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finding/presentation/widgets/finding_category_style.dart';
import 'package:finding/data/datasources/finding_remote_datasource.dart';

class FindingListPage extends StatelessWidget {
  const FindingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<FindingBloc>()..add(const LoadFindings()),
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
  bool _isFirstLoad = true;
  UserRole _role = UserRole.unknown;
  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _syncColors();
  }

  Future<void> _syncColors() async {
    await GetIt.instance<FindingRemoteDatasource>().syncCategoryColors();
    if (mounted) setState(() {});
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _role = UserRole.fromApi(prefs.getString('user_role'));
        _userName = prefs.getString('user_name') ?? '';
        _userId = prefs.getString('user_id') ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            _isFirstLoad = false;
          }
        },
        builder: (context, state) {
          final isLoading = state is FindingLoading || state is FindingInitial;
          final findings =
              state is FindingLoaded ? state.findings : _lastFindings;

          if (state is FindingError) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FindingBloc>().add(const LoadFindings());
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 40,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      state.message.replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => context.read<FindingBloc>().add(
                          const LoadFindings(),
                        ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          // Skeleton placeholder saat first load
          // Gunakan jumlah data sebelumnya agar tidak misleading. Jika kosong & bukan first load, count = 0
          final skeletonCount = _isFirstLoad ? 3 : _lastFindings.length;
          final skeletonList = List.generate(
            skeletonCount,
            (_) => Finding(
              id: '',
              category: const FindingCategory(id: '', name: 'OFI'),
              description: 'Loading Description Here',
              clauseRef: '-',
              foundAt: DateTime.now(),
              status: FindingStatus.open,
              department: 'Department Name',
              reporter: '',
              reporterId: '',
            ),
          );

          // Filter findings: hide if Closed > 24 hours ago
          final filteredFindings =
              findings.where((finding) {
                if (finding.status == FindingStatus.closed) {
                  if (finding.capaClosedAt != null) {
                    final diff = DateTime.now().toUtc().difference(
                      finding.capaClosedAt!.toUtc(),
                    );
                    return diff.inHours < 24;
                  }
                  return false; // sembunyikan jika tidak ada tanggal close
                }
                return true;
              }).toList();

          final displayList = isLoading ? skeletonList : filteredFindings;

          final sortedFindings = List.of(displayList)..sort((a, b) {
            final r = FindingCategoryStyle.rank(
              a.category.name,
            ).compareTo(FindingCategoryStyle.rank(b.category.name));
            return r != 0 ? r : a.category.name.compareTo(b.category.name);
          });

          return Stack(
            children: [
              // Empty state centered exactly on the screen
              if (!isLoading && sortedFindings.isEmpty)
                const Center(
                  child: Text(
                    'No Finding is available',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              RefreshIndicator(
                onRefresh: () async {
                  context.read<FindingBloc>().add(const LoadFindings());
                  _syncColors();
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: Skeletonizer(
                  enabled: isLoading,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      if (isLoading || sortedFindings.isNotEmpty)
                        ...sortedFindings.map(
                          (finding) => _FindingCard(
                            finding: finding,
                            role: _role,
                            userName: _userName,
                            userId: _userId,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // FAB tambah finding baru
              // FAB tambah finding baru
              if (_role.canCreateFinding)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;

                      // ukuran FAB dinamis seperti AuditListPage
                      final fabSize = (screenWidth * 0.18).clamp(64.0, 88.0);

                      return SizedBox(
                        width: fabSize,
                        height: fabSize,
                        child: FloatingActionButton(
                          backgroundColor: AppColors.primaryLight,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(fabSize * 0.25),
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
  final UserRole role;
  final String userName;
  final String userId;

  const _FindingCard({
    required this.finding,
    required this.role,
    required this.userName,
    required this.userId,
  });

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
                  // ✅ Tombol Edit — tampilkan jika QM atau (Auditor dan reporter name sama dengan user_name)
                  // Quality Manager boleh mengubah finding siapa pun;
                  // role lain hanya finding yang dia laporkan sendiri.
                  if (role.canEditOthersFinding || finding.reporter == userName)
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
                    )
                  else
                    const SizedBox.shrink(), // Kosong jika tidak boleh edit
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

  Color _getCardBackgroundColor() =>
      finding.id.isEmpty
          ? Colors.grey.shade100
          : FindingCategoryStyle.cardBackground(finding.category.name);

  Color _getBorderColor() =>
      finding.id.isEmpty
          ? Colors.grey.shade300
          : FindingCategoryStyle.color(finding.category.name);

  String _getBadgeLabel() => finding.category.label;

  Color _getBadgeColor() =>
      FindingCategoryStyle.badgeBackground(finding.category.name);

  Color _getBadgeTextColor() =>
      FindingCategoryStyle.color(finding.category.name);

  Widget _buildCategoryBadge() {
    if (finding.id.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Loading',
          style: TextStyle(color: Colors.transparent),
        ),
      );
    }
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
}
