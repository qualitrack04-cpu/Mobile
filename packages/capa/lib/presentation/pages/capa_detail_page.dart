import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:capa/domain/entities/capa.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';
import 'package:capa/presentation/bloc/capa_state.dart';
import 'package:get_it/get_it.dart';
import 'package:core/app_colors.dart';
import 'package:core/core.dart';
import 'package:google_fonts/google_fonts.dart';

class CapaDetailPage extends StatelessWidget {
  final String capaId;

  const CapaDetailPage({super.key, required this.capaId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider.value(
      value:
          GetIt.instance<CapaBloc>()
            ..add(LoadCapaDetail(id: capaId)), // ✅ GetIt.instance
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
            'CAPA Detail',
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

            if (state is CapaDetailLoaded) {
              return _buildDetail(context, state.capa);
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Capa capa) {
    final picName =
        capa.picName.isNotEmpty ? capa.picName : capa.picId.toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _breakable(capa.rootCause),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2B55),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // PIC
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _breakable(picName),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            _buildSection(
              label: 'FINDINGS',
              value:
                  capa.findingTitle.isNotEmpty
                      ? capa.findingTitle
                      : capa.rootCause,
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            _buildSection(label: 'ACTION', value: capa.correctiveAction),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Due date
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DUE DATE:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppClock.formatDate(capa.deadline, convert: false),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status: warna dan nama mengikuti /api/system-config/capa-statuses.
            if (capa.status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusChip(capa),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Capa capa) {
    final color = CapaStatusStyle.color(capa.status);
    final isTerminal = CapaStatusStyle.isTerminal(capa.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CapaStatusStyle.background(capa.status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTerminal ? Icons.check_circle : Icons.circle,
            size: isTerminal ? 16 : 8,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            capa.status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _breakable(String text) => text.split('').join('\u200B');
}