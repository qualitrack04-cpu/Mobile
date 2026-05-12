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

  List<AuditEntity> _applyFilter(List<AuditEntity> audits) {
    final filtered = _isPrioritySelected
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
          'AUDIT PLAN',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.07).clamp(24.0, 34.0),
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),

      body: Column(
        children: [
          AuditFilter(
            isPrioritySelected: _isPrioritySelected,
            onChanged: (value) => setState(() => _isPrioritySelected = value),
          ),
          Expanded(child: _buildBody()),
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
            // BLoC sudah reload otomatis setelah create — tidak perlu setState
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

  Widget _buildBody() {
    return BlocConsumer<AuditBloc, AuditState>(
      listener: (context, state) {
        if (state is AuditError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuditLoading || state is AuditInitial;
        final audits = state is AuditLoaded ? state.audits : <AuditEntity>[];

        final displayList = isLoading
            ? List.generate(
                4,
                (_) => AuditEntity(
                  title: 'Loading Audit Title',
                  auditorName: 'Loading Name',
                  isoTemplates: const ['ISO 9001:2015'],
                  department: 'Department',
                  date: DateTime.now(),
                  description: '',
                  isPriority: false,
                  isFinished: false,
                ),
              )
            : _applyFilter(audits);

        if (!isLoading && displayList.isEmpty) {
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

        return Skeletonizer(
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
                  // BLoC reload otomatis setelah update
                },

                onChecklist: audit.isFinished
                    ? null
                    : () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<AuditBloc>(),
                              child: AuditChecklistPage(audit: audit),
                            ),
                          ),
                        );

                        if (result == true) {
                          // MarkAuditFinished sudah di-dispatch dari AuditChecklistPage
                          // BLoC akan reload list otomatis
                        }
                      },

                onDelete: () {
                  context.read<AuditBloc>().add(DeleteAuditEvent(audit: audit));
                },
              );
            },
          ),
        );
      },
    );
  }
}