import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../data/datasources/checklist_datasource.dart';
import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/checklist_entity.dart';
import '../widgets/checklist_card.dart';

class AuditChecklistPage extends StatefulWidget {
  final AuditEntity audit;

  const AuditChecklistPage({
    super.key,
    required this.audit,
  });

  @override
  State<AuditChecklistPage> createState() => _AuditChecklistPageState();
}

class _AuditChecklistPageState extends State<AuditChecklistPage> {
  final ChecklistDatasource _datasource = ChecklistDatasource();

  List<ChecklistEntity> _checklists = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'Safety',
    'Process',
    'Documentation',
    'Maintenance',
  ];

  String _selectedCategory = 'Safety';

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => _isLoading = true);

    final result = await _datasource.getChecklist();

    setState(() {
      _checklists = result;
      _isLoading = false;
    });
  }

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = widget.audit.date;
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<ChecklistEntity> get _filteredChecklists =>
      _checklists.where((e) => e.category == _selectedCategory).toList();

  int get _completedCount =>
      _checklists.where((e) => e.isPassed != null).length;

  double get _progress =>
      _checklists.isEmpty ? 0 : _completedCount / _checklists.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
          ),
        ),

        title: Text(
          'Audit Checklist',
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),

      // ✅ Skeletonizer membungkus seluruh body
      body: Skeletonizer(
        enabled: _isLoading,
        child: Column(
          children: [
            _buildInfoCard(),
            _buildCategoryTabs(),
            const Divider(height: 1),
            _buildChecklistContent(),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ✅ FAB selalu tampil, ikut skeleton — tidak ada animasi putar lagi
      floatingActionButton: Skeletonizer(
        enabled: _isLoading,
        child: _buildSubmitButton(),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            widget.audit.department,
            style: GoogleFonts.inter(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Wrap(
                spacing: 6,
                children: widget.audit.isoTemplates.map((iso) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0FA),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      iso,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'COMPLETION',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),

                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 8),

              Text(
                _formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,

        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },

            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),

              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),

              alignment: Alignment.center,

              child: Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryLight
                      : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChecklistContent() {
    // ✅ dummy data untuk skeleton saat loading
    final displayList = _isLoading
        ? List.generate(3, (_) => ChecklistEntity(
            title: 'Loading Checklist Item Title',
            description:
                'Loading description text that is quite long enough to show',
            category: _selectedCategory,
            isPassed: null,
            hasFinding: false,
          ))
        : _filteredChecklists;

    if (!_isLoading && displayList.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No checklist for this category',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }

    return Expanded(
      // ✅ tidak perlu Skeletonizer di sini, sudah ditangani parent
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 120),
        itemCount: displayList.length,

        itemBuilder: (context, index) {
          final checklist = displayList[index];

          return ChecklistCard(
            checklist: checklist,

            onPass: _isLoading
                ? null
                : () {
                    setState(() => checklist.isPassed = true);
                  },

            onFail: _isLoading
                ? null
                : () {
                    setState(() => checklist.isPassed = false);
                  },

            onAddFinding: _isLoading
                ? null
                : () {
                    setState(() => checklist.hasFinding = true);
                  },

            onEditFinding: _isLoading
                ? null
                : () {
                    debugPrint('Edit Finding');
                  },
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 280,
      height: 56,

      child: ElevatedButton(
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!context.mounted) return;
          Navigator.pop(context, true);
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        child: Text(
          'Submit Checklist',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}