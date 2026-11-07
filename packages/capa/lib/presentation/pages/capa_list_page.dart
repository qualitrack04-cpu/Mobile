import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:capa/domain/entities/capa.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';
import 'package:capa/presentation/bloc/capa_state.dart';
import 'package:capa/presentation/pages/capa_form_page.dart';
import 'package:capa/presentation/pages/capa_detail_page.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:core/core.dart';
import 'package:core_services/core_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finding/presentation/widgets/finding_category_style.dart';
import 'package:finding/data/datasources/finding_remote_datasource.dart';

class CapaListPage extends StatelessWidget {
  const CapaListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.instance<CapaBloc>()..add(const LoadCapas()),
      child: const _CapaListView(),
    );
  }
}

class _CapaListView extends StatefulWidget {
  const _CapaListView();

  @override
  State<_CapaListView> createState() => _CapaListViewState();
}

class _CapaListViewState extends State<_CapaListView> {
  List<Capa> _lastCapas = [];
  bool _isFirstLoad = true;
  UserRole _role = UserRole.unknown;
  String _userId = '';
  String _userName = '';

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
        _userId = prefs.getString('user_id') ?? '';
        _userName = prefs.getString('user_name') ?? '';
      });
    }
  }

  List<Capa> _filterCapas(List<Capa> capas) {
    final now = DateTime.now();
    return capas.where((capa) {
      if (capa.status == 'Closed') {
        if (capa.closedAt != null) {
          // Pastikan perbedaan waktu dihitung dalam UTC untuk menghindari masalah zona waktu
          final diff = now.toUtc().difference(capa.closedAt!.toUtc());
          return diff.inHours < 24;
        }
        // Jika statusnya Closed tapi tidak ada data closedAt, sembunyikan saja.
        return false;
      }
      return true; // Tampilkan yang Open, In Progress, Pending Verification
    }).toList();
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
          'CAPA',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: BlocConsumer<CapaBloc, CapaState>(
        listener: (context, state) {
          if (state is CapaLoaded) {
            _lastCapas = state.capas;
            _isFirstLoad = false;
          }
        },
        builder: (context, state) {
          final isLoading = state is CapaLoading || state is CapaInitial;
          final capas = state is CapaLoaded ? state.capas : _lastCapas;

          if (state is CapaError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Skeleton placeholder saat first load
          // Gunakan jumlah data sebelumnya agar tidak misleading
          final skeletonCount = _isFirstLoad ? 3 : _lastCapas.length;
          final skeletonList = List.generate(
            skeletonCount,
            (_) => Capa(
              id: '',
              findingId: '',
              findingCategory:
                  'OFI', // OFI menggunakan warna netral (abu/biru muda)
              findingTitle: 'Loading Finding Title',
              picId: '',
              picName: 'Loading PIC Name',
              rootCause: 'Loading Root Cause',
              correctiveAction: 'Loading Corrective Action Here',
              preventiveAction: '',
              deadline: DateTime.now(),
              isClosed: false,
              status: 'Pending Verification', // Status yang warnanya netral
              createdAt: DateTime.now(),
            ),
          );

          final filteredCapas = _filterCapas(capas);

          filteredCapas.sort((a, b) {
            final aDone = CapaStatusStyle.isTerminal(a.status);
            final bDone = CapaStatusStyle.isTerminal(b.status);
            if (aDone && !bDone) return 1;
            if (!aDone && bDone) return -1;
            return a.deadline.compareTo(b.deadline);
          });

          final displayList = isLoading ? skeletonList : filteredCapas;

          return Stack(
            children: [
              // Empty state centered exactly on the screen
              if (!isLoading && displayList.isEmpty)
                const Center(
                  child: Text(
                    'No CAPA is available',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              RefreshIndicator(
                onRefresh: () async {
                  context.read<CapaBloc>().add(const LoadCapas());
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                child: Skeletonizer(
                  enabled: isLoading,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      if (isLoading || displayList.isNotEmpty)
                        ...displayList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final capa = entry.value;
                          return _CapaCard(
                            key:
                                capa.id.isEmpty
                                    ? ValueKey('skeleton_$index')
                                    : ValueKey(capa.id),
                            capa: capa,
                            role: _role,
                            userId: _userId,
                            userName: _userName,
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // FAB
              // FAB
              if (_role.canManageCapa)
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
                            final bloc = context.read<CapaBloc>();

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => BlocProvider.value(
                                      value: bloc,
                                      child: const CapaFormPage(),
                                    ),
                              ),
                            );

                            if (result == true && context.mounted) {
                              bloc.add(const LoadCapas());
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

class _CapaCard extends StatefulWidget {
  final Capa capa;
  final UserRole role;
  final String userId;
  final String userName;

  const _CapaCard({
    super.key,
    required this.capa,
    required this.role,
    required this.userId,
    required this.userName,
  });

  @override
  State<_CapaCard> createState() => _CapaCardState();
}

class _CapaCardState extends State<_CapaCard> {
  late String _currentStatus;

  /// Auditee hanya boleh sampai Pending Verification.
  /// Status Closed khusus Quality Manager / Auditor Internal.
  List<String> get _availableStatuses {
    final all = CapaStatusStyle.names;
    final options =
        widget.role.canManageCapa
            ? all
            : all.where((s) => !CapaStatusStyle.isTerminal(s)).toList();
    // Status CAPA ini bisa sudah dinonaktifkan admin; dropdown tetap butuh itemnya.
    if (_currentStatus.isNotEmpty && !options.contains(_currentStatus)) {
      return [_currentStatus, ...options];
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.capa.status;
  }

  /// PIC dicocokkan lewat ID atau nama user yang sedang login.
  bool get _isMyCapa {
    final picId = widget.capa.picId;
    final sameId =
        picId.isNotEmpty &&
        widget.userId.isNotEmpty &&
        widget.userId.toLowerCase() != 'null' &&
        picId.toLowerCase() == widget.userId.toLowerCase();
    String normalizeName(String value) =>
        value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    final sameName =
        widget.capa.picName.isNotEmpty &&
        widget.userName.isNotEmpty &&
        normalizeName(widget.capa.picName) == normalizeName(widget.userName);

    return sameId || sameName;
  }

  /// Status boleh diubah oleh Quality Manager, atau oleh PIC-nya sendiri.
  bool get _canChangeStatus =>
      widget.role.canManageCapa || (widget.role.canFillOwnCapa && _isMyCapa);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.capa.rootCause,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D2B55),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppClock.formatDate(widget.capa.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ✅ dropdown status menggantikan static badge
                _buildStatusDropdown(context),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              widget.capa.correctiveAction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),

            Row(
              children: [
                // Nama PIC dibatasi: ambil sisa ruang, dipotong "..." jika kepanjangan
                Expanded(
                  child: Text(
                    widget.capa.picName.isNotEmpty
                        ? widget.capa.picName
                        : widget.capa.picId.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Details selalu terlihat dan bisa ditekan
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CapaDetailPage(capaId: widget.capa.id),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
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

  Widget _buildStatusDropdown(BuildContext context) {
    if (widget.capa.id.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
    final isTerminal = CapaStatusStyle.isTerminal(_currentStatus);
    final hasStatus = _currentStatus.isNotEmpty;
    final Color textColor =
        hasStatus ? CapaStatusStyle.color(_currentStatus) : Colors.black38;
    final Color bgColor =
        hasStatus
            ? CapaStatusStyle.background(_currentStatus)
            : const Color(0xFFF0F0F0);

    if (!_canChangeStatus || isTerminal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _currentStatus.isEmpty ? 'Status' : _currentStatus,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentStatus.isEmpty ? null : _currentStatus,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: textColor),
          hint: Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items:
              _availableStatuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: CapaStatusStyle.color(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          onChanged:
              CapaStatusStyle.isTerminal(widget.capa.status)
                  ? null
                  : (newStatus) async {
                    if (newStatus == null) return;
                    final goesTerminal = CapaStatusStyle.isTerminal(newStatus);

                    if (goesTerminal && !widget.role.canManageCapa) return;

                    if (goesTerminal) {
                      // ... dialog konfirmasi + simpan pref, tidak berubah
                    }

                    setState(() => _currentStatus = newStatus);

                    if (!context.mounted) return;
                    context.read<CapaBloc>().add(
                      UpdateCapaStatusEvent(
                        id: widget.capa.id,
                        status: newStatus,
                      ),
                    );
                  },
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (widget.capa.id.isEmpty || widget.capa.findingCategory.isEmpty) {
      return Colors.grey.shade300;
    }
    return FindingCategoryStyle.color(widget.capa.findingCategory);
  }
}
