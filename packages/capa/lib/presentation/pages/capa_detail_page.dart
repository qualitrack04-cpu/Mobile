import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:capa/domain/entities/capa.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';
import 'package:capa/presentation/bloc/capa_state.dart';
import 'package:mobile/injector.dart';

class CapaDetailPage extends StatelessWidget {
  final String capaId;

  const CapaDetailPage({super.key, required this.capaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CapaBloc>()..add(LoadCapaDetail(id: capaId)),
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
            'QualiTrack',
            style: TextStyle(
              color: Color(0xFF0D2B55),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocBuilder<CapaBloc, CapaState>(
          builder: (context, state) {
            if (state is CapaLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D2B55),
                ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CAPA Detail',
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Root Cause sebagai judul
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    capa.rootCause,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                ),
                const Divider(height: 1),

                // PIC
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        capa.picId.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Problem Title / Root Cause
                _buildSection(
                  label: 'PROBLEM TITLE',
                  value: capa.rootCause,
                ),
                const Divider(height: 1),

                // Action
                _buildSection(
                  label: 'ACTION',
                  value: capa.correctiveAction,
                ),
                const Divider(height: 1),

                // Preventive Action
                _buildSection(
                  label: 'PREVENTIVE ACTION',
                  value: capa.preventiveAction,
                ),
                const Divider(height: 1),

                // Due Date
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
                      const Spacer(),
                      Text(
                        '${capa.deadline.day} ${_getMonth(capa.deadline.month)} ${capa.deadline.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                if (capa.isClosed)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Closed',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required String value,
  }) {
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
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
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