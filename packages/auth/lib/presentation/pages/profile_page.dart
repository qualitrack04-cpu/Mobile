import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:core_services/services/api_service.dart';
import 'package:get_it/get_it.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = '';
  String _email = '';
  String _role = '';
  String _photoPath = '';
  bool _isLoading = true;
  bool _showMenu = false;

  // Dummy data — nanti diganti dari API
  final List<RecentActivityItem> _activities = [
    RecentActivityItem(
      type: 'success',
      title: 'Closed Audit #AQ-4092 - Manufacturing Site A',
      subtitle: 'CAPA dan Finding berhasil diselesaikan',
      timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
    ),
    RecentActivityItem(
      type: 'update',
      title: 'Updated CAPA Implementation Plan for Log #X22',
      subtitle: 'Status CAPA diperbarui',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 40)),
    ),
    RecentActivityItem(
      type: 'critical',
      title: 'Major Non-Conformity Identified - Audit #NC-551',
      subtitle: 'Card overdue berhasil diselesaikan',
      timestamp: DateTime(2023, 11, 12),
    ),
  ];
  final bool _activitiesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        _buildInfoCard(),
                        _buildQualityScore(),
                        _buildSuccessRate(),
                        _buildAuditStats(17, 1),
                        _buildRecentActivity(),
                      ],
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
              _formatRole(_role).toUpperCase(),
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
            _buildInfoField(label: 'Role', value: _formatRole(_role)),
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

  Widget _buildQualityScore() {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 5, vertical: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsGeometry.symmetric(
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
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: 0.92,
                        strokeWidth: 12,
                        color: const Color(0xFFF59E0B),
                        backgroundColor: AppColors.borderLight,
                      ),
                    ),

                    Text(
                      '92%',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Excellent',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRate() {
    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: 5, vertical: 10),
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
                Text(
                  '90%',
                  style: GoogleFonts.inter(
                    color: AppColors.surface,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '18/20',
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
                value: 0.9,
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

  Widget _buildAuditStats(int onTime, int overdue) {
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

  Widget _buildActivityItem(RecentActivityItem item) {
    // Konfigurasi per tipe
    final config = _activityConfig(item.type);

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

          // Title + subtitle + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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
                fontSize: 12,
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

  Map<String, dynamic> _activityConfig(String type) {
    switch (type) {
      case 'success':
        return {
          'icon': Icons.check_circle_outline_rounded,
          'iconColor': AppColors.success,
          'bgColor': AppColors.successLight,
          'label': 'SUCCESS',
          'badgeBg': AppColors.successLight,
          'badgeText': AppColors.success,
        };
      case 'critical':
        return {
          'icon': Icons.warning_amber_rounded,
          'iconColor': AppColors.danger,
          'bgColor': AppColors.dangerLight,
          'label': 'CRITICAL',
          'badgeBg': AppColors.dangerLight,
          'badgeText': AppColors.danger,
        };
      case 'update':
      default:
        return {
          'icon': Icons.edit_note_rounded,
          'iconColor': const Color(0xFF2563EB),
          'bgColor': const Color(0xFFEFF6FF),
          'label': 'UPDATE',
          'badgeBg': const Color(0xFFEFF6FF),
          'badgeText': const Color(0xFF2563EB),
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

// ────────────────────────────────────────────────
// Model lokal: RecentActivityItem
// Nanti bisa dipindah ke service saat API sudah siap
// ────────────────────────────────────────────────
class RecentActivityItem {
  final String type;        // 'success' | 'update' | 'critical'
  final String title;
  final String subtitle;
  final DateTime? timestamp;

  const RecentActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.timestamp,
  });
}
