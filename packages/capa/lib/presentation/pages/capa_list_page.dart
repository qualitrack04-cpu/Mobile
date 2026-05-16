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
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
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
                    findingCategory: 'OFI', // OFI menggunakan warna netral (abu/biru muda)
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

                final displayList = isLoading ? skeletonList : capas;

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        context.read<CapaBloc>().add(const LoadCapas());
                        await Future.delayed(const Duration(milliseconds: 800));
                      },
                      child: Skeletonizer(
                        enabled: isLoading,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          children: [
                            if (!isLoading && displayList.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 100),
                                  child: Text(
                                    'Belum ada CAPA',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...displayList.map((capa) => _CapaCard(capa: capa)),
                          ],
                        ),
                      ),
                    ),

                    // FAB
                      // FAB
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
  const _CapaCard({required this.capa});

  @override
  State<_CapaCard> createState() => _CapaCardState();
}

class _CapaCardState extends State<_CapaCard> {
  late String _currentStatus;

  // ✅ opsi dropdown status
  static const List<String> _statusOptions = ['Open', 'In Progress', 'Pending Verification', 'Closed'];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.capa.status;
  }

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
                        '${_getMonth(widget.capa.createdAt.month)} ${widget.capa.createdAt.day}, ${widget.capa.createdAt.year}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.capa.picName.isNotEmpty ? widget.capa.picName : widget.capa.picId.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2B55),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CapaDetailPage(capaId: widget.capa.id),
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
                      Icon(Icons.chevron_right, color: Color(0xFF0D2B55), size: 18),
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
        child: const Text('Loading', style: TextStyle(color: Colors.transparent)),
      );
    }

    // ✅ warna sesuai status
    Color bgColor;
    Color textColor;

    switch (_currentStatus) {
      case 'Closed':
        bgColor = const Color(0xFFD5F5E3);
        textColor = Colors.green;
        break;
      case 'In Progress':
        bgColor = const Color(0xFFFFEDD5);
        textColor = Colors.orange;
        break;
      case 'Open':
        bgColor = const Color(0xFFFFDDDD);
        textColor = Colors.red;
        break;
      default:
        // ✅ status kosong: tampil placeholder "Status"
        bgColor = const Color(0xFFF0F0F0);
        textColor = Colors.black38;
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
          items: _statusOptions.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus == null) return;
            setState(() => _currentStatus = newStatus);

            // ✅ kirim event ke bloc
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
    if (widget.capa.id.isEmpty) return Colors.grey.shade300; // Skeleton
    switch (widget.capa.findingCategory) {
      case 'MajorNC':
        return Colors.red;
      case 'MinorNC':
        return Colors.orange;
      case 'Observation':
        return Colors.green;
      case 'OFI':
        return const Color(0xFF3B6FD4);
      default:
        return Colors.grey.shade300;
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}