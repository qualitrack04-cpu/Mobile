import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';

import '../../data/datasources/audit_datasource.dart';
import '../../domain/entities/audit_entity.dart';

import '../widgets/audit_card.dart';
import '../widgets/audit_filter.dart';

import 'audit_form_page.dart';
import 'audit_checklist_page.dart';

import 'package:skeletonizer/skeletonizer.dart';

class AuditListPage extends StatefulWidget {
  const AuditListPage({super.key});

  @override
  State<AuditListPage> createState() => _AuditListPageState();
}

class _AuditListPageState extends State<AuditListPage> {
  final AuditDatasource _datasource = AuditDatasource();

  List<AuditEntity> _audits = [];
  bool _isLoading = true; // ✅ tambah loading state

  bool _isPrioritySelected = false;

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    // ✅ pastikan loading state aktif sebelum fetch
    setState(() => _isLoading = true);

    final result = await _datasource.getAudits();

    setState(() {
      _audits = result;
      _isLoading = false;
    });
  }

  List<AuditEntity> get _filteredAudits {
    final filtered = _isPrioritySelected
        ? _audits.where((e) => e.isPriority).toList()
        : List<AuditEntity>.from(_audits);

    // ✅ sort: yang belum selesai di atas
    filtered.sort((a, b) {
      if (a.isFinished == b.isFinished) return 0;
      return a.isFinished ? 1 : -1;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        title: Text(
          'AUDIT PLAN',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),

      body: Column(
        children: [
          AuditFilter(
            isPrioritySelected: _isPrioritySelected,
            onChanged: (value) {
              setState(() {
                _isPrioritySelected = value;
              });
            },
          ),

          Expanded(child: _buildBody()),
        ],
      ),

      floatingActionButton: SizedBox(
        width: 80, // ← ubah sesuai selera
        height: 80, // ← ubah sesuai selera

        child: FloatingActionButton(
          backgroundColor: AppColors.primaryLight,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // ← ubah sesuai selera
          ),

          onPressed: () async {
            final newAudit = await Navigator.push<AuditEntity>(
              context,
              MaterialPageRoute(builder: (context) => const AuditFormPage()),
            );

            if (newAudit != null) {
              setState(() {
                _audits.add(newAudit);
              });
            }
          },

          child: const Icon(
            Icons.add,
            size: 36,
            color: Colors.white,
          ), // ← ubah sesuai selera
        ),
      ),
    );
  }

  Widget _buildBody() {
    // ✅ skeleton pakai data dummy saat loading
    final displayList = _isLoading
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
        : _filteredAudits;

    if (!_isLoading && displayList.isEmpty) {
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

    // ✅ bungkus ListView dengan Skeletonizer
    return Skeletonizer(
      enabled: _isLoading,

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
                MaterialPageRoute(builder: (_) => AuditFormPage(audit: audit)),
              );
              _loadAudits();
            },

            onChecklist: audit.isFinished
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuditChecklistPage(audit: audit),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        final index = _audits.indexOf(audit);
                        _audits[index] = audit.copyWith(isFinished: true);
                      });
                    }
                  },

            onDelete: () {
              setState(() {
                _audits.remove(audit);
              });
            },
          );
        },
      ),
    );
  }
}
