import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:capa/domain/entities/capa.dart';
import 'package:capa/presentation/bloc/capa_bloc.dart';
import 'package:capa/presentation/bloc/capa_event.dart';
import 'package:capa/presentation/bloc/capa_state.dart';
import 'package:capa/presentation/pages/capa_form_page.dart';
import 'package:capa/presentation/pages/capa_detail_page.dart';
import 'package:mobile/injector.dart';

class CapaListPage extends StatelessWidget {
  const CapaListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CapaBloc>()..add(const LoadCapas()),
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

            if (state is CapaLoaded) {
              if (state.capas.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada CAPA',
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
                  const Text(
                    'CAPA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...state.capas.map(
                    (capa) => _CapaCard(capa: capa),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              backgroundColor: const Color(0xFF0D2B55),
              onPressed: () async {
                final bloc = context.read<CapaBloc>();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: bloc,
                      child: const CapaFormPage(),
                    ),
                  ),
                );
                if (result == true && context.mounted) {
                  bloc.add(const LoadCapas());
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            );
          },
        ),
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    capa.rootCause,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2B55),
                    ),
                  ),
                ),
                Text(
                  '${capa.createdAt.day} ${_getMonth(capa.createdAt.month)} ${capa.createdAt.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Corrective Action
            Text(
              capa.correctiveAction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const Divider(height: 24),

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

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}