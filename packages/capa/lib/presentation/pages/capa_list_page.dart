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

class CapaListPage extends StatelessWidget {
  const CapaListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<CapaBloc>()..add(const LoadCapas()),
      child: Builder(
        builder: (context) {
          // ✅ Tambahkan ini
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
            body: BlocBuilder<CapaBloc, CapaState>(
              builder: (context, state) {
                if (state is CapaLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D2B55)),
                  );
                }

                if (state is CapaError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is CapaLoaded) {
                  return Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        children: [
                          if (state.capas.isEmpty)
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
                            ...state.capas.map((capa) => _CapaCard(capa: capa)),
                        ],
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
                }

                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
  }
}

class _CapaCard extends StatelessWidget {
  final Capa capa;

  const _CapaCard({required this.capa});

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
            // Title + Badge + Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capa.rootCause,
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
                        '${_getMonth(capa.createdAt.month)} ${capa.createdAt.day}, ${capa.createdAt.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 8),

            // Corrective Action
            Text(
              capa.correctiveAction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),

            // PIC + Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  capa.picId,
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
                        builder: (_) => CapaDetailPage(capaId: capa.id),
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
    if (capa.isClosed) return Colors.green;
    // Cek deadline untuk In Progress
    final now = DateTime.now();
    final diff = capa.deadline.difference(now).inDays;
    if (diff <= 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatusBadge() {
    String label;
    Color bgColor;
    Color textColor;

    if (capa.isClosed) {
      label = 'Done';
      bgColor = const Color(0xFFD5F5E3);
      textColor = Colors.green;
    } else {
      final now = DateTime.now();
      final diff = capa.deadline.difference(now).inDays;
      if (diff <= 30) {
        label = 'In Progress';
        bgColor = const Color(0xFFFFEDD5);
        textColor = Colors.orange;
      } else {
        label = 'Open';
        bgColor = const Color(0xFFFFDDDD);
        textColor = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
