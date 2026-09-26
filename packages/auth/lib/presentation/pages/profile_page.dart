import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:core_services/services/api_service.dart';
import 'package:core_services/services/quality_score_service.dart';
import 'package:core_services/services/profile_service.dart';
import 'package:get_it/get_it.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String _name = '';
  String _email = '';
  String _role = '';
  String _photoPath = '';
  bool _isLoading = true;
  bool _showMenu = false;

  // Quality Score dari API
  double _qualityScore = 0;
  bool _qualityScoreLoading = true;
  late AnimationController _scoreAnimController;
  late Animation<double> _scoreAnim;

  // KPI dari API
  UserKpi? _kpi;
  bool _kpiLoading = true;

  // Recent Activity dari API
  List<UserRecentActivity> _activities = [];
  bool _activitiesLoading = true;

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
    );
    _loadUserData();
    _loadQualityScore();
    _loadKpi();
    _loadRecentActivities();
  }

  @override
  void dispose() {
    _scoreAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadQualityScore() async {
    final service = GetIt.instance<QualityScoreService>();
    final score = await service.getLatestQualityScore();
    if (mounted) {
      setState(() {
        _qualityScore = score ?? 0;
        _qualityScoreLoading = false;
      });
      // Mulai animasi lingkaran dari 0 ke nilai aktual
      _scoreAnim = Tween<double>(begin: 0, end: _qualityScore / 100).animate(
        CurvedAnimation(parent: _scoreAnimController, curve: Curves.easeOutCubic),
      );
      _scoreAnimController.forward(from: 0);
    }
  }

  Future<void> _loadKpi() async {
    final service = GetIt.instance<ProfileService>();
    final kpi = await service.getKpi();
    if (mounted) {
      setState(() {
        _kpi = kpi;
        _kpiLoading = false;
      });
    }
  }

  Future<void> _loadRecentActivities() async {
    final service = GetIt.instance<ProfileService>();
    final activities = await service.getRecentActivity();
    if (mounted) {
      setState(() {
        _activities = activities;
        _activitiesLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadUserData(),
      _loadQualityScore(),
      _loadKpi(),
      _loadRecentActivities(),
    ]);
  }

  Future<void> _loadUserData() async {
    final authService = GetIt.instance<AuthService>();
    try {
      await authService.fetchProfile();
    } catch (_) {}

    final user = await authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _name = user['name'] ?? '';
        _email = user['email'] ?? '';
        _role = user['role'] ?? '';
        _photoPath = user['photo'] ?? '';
        _isLoading = false;
      });
    }
  }

  String _formatRole(String role) {
    if (role == 'Auditor' || role == 'AuditorInternal')
      return 'Auditor Internal';
    if (role.isEmpty) return '-';
    return role
        .replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (Match m) => ' ${m[1]}')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
          'Profile',
          style: GoogleFonts.inter(
            fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showMenu = !_showMenu),
            icon: Icon(
              _showMenu ? Icons.keyboard_arrow_up : Icons.menu,
              color: AppColors.primary,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _refreshAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          _buildInfoCard(),
                          if (UserRole.fromApi(_role) != UserRole.qualityManager) ...[
                            _buildQualityScore(),
                            _buildSuccessRate(),
                            _buildAuditStats(),
                            _buildRecentActivity(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Dropdown menu
                  if (_showMenu)
                    Positioned(
                      top: 0,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() => _showMenu = false);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditProfilePage(
                                          name: _name,
                                          email: _email,
                                          role: _role,
                                          photoPath: _photoPath,
                                        ),
                                  ),
                                ).then((_) => _loadUserData());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Colors.black87,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit Profile',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Divider(height: 1),

                            InkWell(
                              onTap: () {
                                setState(() => _showMenu = false);
                                _showLogoutDialog(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout_rounded,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Log Out',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.borderLight,
              backgroundImage:
                  _photoPath.isNotEmpty
                      ? NetworkImage(ApiService.fixImageUrl(_photoPath))
                      : null,
              child:
                  _photoPath.isEmpty
                      ? Icon(
                        Icons.person,
                        size: 52,
                        color: AppColors.primaryMuted,
                      )
                      : null,
            ),
            const SizedBox(height: 14),
            Text(
              _name.isEmpty ? '-' : _name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              UserRole.fromApi(_role).label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoField(
              label: 'Username',
              value: _name.isEmpty ? '-' : _name,
            ),
            _buildInfoField(
              label: 'Email',
              value: _email.isEmpty ? '-' : _email,
            ),
            _buildInfoField(
              label: 'Role',
              value: UserRole.fromApi(_role).label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hitung warna & label berdasarkan nilai score
  Color _scoreColor(double score) {
    if (score >= 85) return const Color(0xFF16A34A);  // hijau
    if (score >= 70) return const Color(0xFFF59E0B);  // kuning
    if (score >= 50) return const Color(0xFFF97316);  // oranye
    return const Color(0xFFEF4444);                   // merah
  }

  String _scoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Poor';
  }

  Widget _buildQualityScore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quality Score',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: _qualityScoreLoading
                  ? const SizedBox(
                      width: 160,
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : AnimatedBuilder(
                      animation: _scoreAnim,
                      builder: (context, _) {
                        final animValue = _scoreAnim.value;
                        final displayScore = (animValue * 100).toStringAsFixed(0);
                        final color = _scoreColor(_qualityScore);
                        return SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: CircularProgressIndicator(
                                  value: animValue,
                                  strokeWidth: 12,
                                  color: color,
                                  backgroundColor: AppColors.borderLight,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$displayScore%',
                                    style: GoogleFonts.inter(
                                      color: color,
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Quality Score',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            Center(
              child: _qualityScoreLoading
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _scoreColor(_qualityScore),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _scoreLabel(_qualityScore),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _scoreColor(_qualityScore),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRate() {
    final rate = _kpi?.onTimeRate ?? _kpi?.onTimeCompletionRate ?? 0.0;
    final percentText = '${(rate * 100).toStringAsFixed(0)}%';
    final onTime =
        _kpi?.totalCompletedOnTime ?? _kpi?.totalCapaClosedOnTime ?? 0;
    final totalClosed = _kpi?.totalCompleted ?? _kpi?.totalCapaClosed ?? 0;
    final ratioText = '$onTime/$totalClosed';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Success Rate',
              style: GoogleFonts.inter(color: AppColors.surface, fontSize: 18),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _kpiLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        percentText,
                        style: GoogleFonts.inter(
                          color: AppColors.surface,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                Text(
                  ratioText,
                  style: GoogleFonts.inter(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: _kpiLoading ? 0.0 : rate.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.textMuted,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditStats([int? customOnTime, int? customOverdue]) {
    final onTime =
      customOnTime ??
      _kpi?.totalCompletedOnTime ??
      _kpi?.totalCapaClosedOnTime ??
      0;
    final totalClosed = _kpi?.totalCompleted ?? _kpi?.totalCapaClosed ?? 0;
    final overdue =
      customOverdue ??
      _kpi?.totalOverdue ??
      (totalClosed - onTime).clamp(0, 999999);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: onTime,
              label: 'ON TIME',
              icon: Icons.alarm_on_outlined,
              iconColor: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              value: overdue,
              label: 'OVERDUE',
              icon: Icons.event_busy_outlined,
              iconColor: const Color(0xFFF04424),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildStatCard({
  required int value,
  required String label,
  required IconData icon,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 24,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: AppColors.borderLight,
        width: 1,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.inter(
                fontSize: 32,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),

        Icon(
          icon,
          size: 42,
          color: iconColor,
        ),
      ],
    ),
  );
}

  // ─────────────────────────────────────────────
  // Recent Activity
  // ─────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (_activitiesLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_activities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 40,
                        color: AppColors.borderLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada aktivitas',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildActivityItem(_activities[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(UserRecentActivity item) {
    // Konfigurasi per tipe
    final config = _activityConfig(item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: config['bgColor'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              config['icon'] as IconData,
              size: 20,
              color: config['iconColor'] as Color,
            ),
          ),
          const SizedBox(width: 12),

          // Title + description + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatActivityTime(item.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: config['badgeBg'] as Color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              config['label'] as String,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: config['badgeText'] as Color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _activityConfig(UserRecentActivity item) {
    switch (item.activityType) {
      case 'CapaVerified':
        final isEffective = !item.description.toLowerCase().contains('tidak');
        if (isEffective) {
          return {
            'icon': Icons.check_circle_outline_rounded,
            'iconColor': AppColors.success,
            'bgColor': AppColors.successLight,
            'label': 'VERIFIED',
            'badgeBg': AppColors.successLight,
            'badgeText': AppColors.success,
            'title': 'CAPA Verified',
          };
        } else {
          return {
            'icon': Icons.cancel_outlined,
            'iconColor': AppColors.danger,
            'bgColor': AppColors.dangerLight,
            'label': 'UNVERIFIED',
            'badgeBg': AppColors.dangerLight,
            'badgeText': AppColors.danger,
            'title': 'CAPA Unverified',
          };
        }
      case 'FindingReported':
        return {
          'icon': Icons.warning_amber_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'bgColor': const Color(0xFFFEF3C7),
          'label': 'FINDING',
          'badgeBg': const Color(0xFFFEF3C7),
          'badgeText': const Color(0xFFB45309),
          'title': 'Finding Reported',
        };
      case 'Audit':
      case 'AuditSubmitted':
      case 'AuditUpdated':
      case 'AuditCompleted':
        return {
          'icon': Icons.fact_check_rounded,
          'iconColor': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFEFF6FF),
          'label': 'AUDIT',
          'badgeBg': const Color(0xFFEFF6FF),
          'badgeText': const Color(0xFF2563EB),
          'title': 'Audit Activity',
        };
      case 'CapaAction':
        return {
          'icon': Icons.task_alt_rounded,
          'iconColor': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFEFF6FF),
          'label': 'ACTION',
          'badgeBg': const Color(0xFFEFF6FF),
          'badgeText': const Color(0xFF2563EB),
          'title': 'CAPA Action',
        };
      default:
        final fallbackTitle = item.activityType.isEmpty
            ? 'Activity'
            : item.activityType.replaceAllMapped(
                RegExp(r'(?<!^)([A-Z])'),
                (match) => ' ${match.group(1)}',
              );
        return {
          'icon': Icons.history_rounded,
          'iconColor': const Color(0xFF6B7280),
          'bgColor': const Color(0xFFF3F4F6),
          'label': 'INFO',
          'badgeBg': const Color(0xFFF3F4F6),
          'badgeText': const Color(0xFF6B7280),
          'title': fallbackTitle,
        };
    }
  }

  String _formatActivityTime(DateTime? dt) {
    if (dt == null) return '-';
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);

    if (diff.inDays == 0) {
      // Today — tampilkan jam
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return 'Today, $h:$m ${local.hour < 12 ? "AM" : "PM"}';
    } else if (diff.inDays == 1) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return 'Yesterday, $h:$m ${local.hour < 12 ? "AM" : "PM"}';
    } else {
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[local.month]} ${local.day}, ${local.year}';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Log Out',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final authService = GetIt.instance<AuthService>();
                  await authService.logout();
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Log Out',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
