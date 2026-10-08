/// Peran pengguna beserta hak aksesnya.
///
/// Satu-satunya tempat role diterjemahkan dan hak aksesnya ditentukan.
/// Jangan membandingkan string role langsung di UI (pola lama
/// `userRole.startsWith('Auditor')`): pola itu menganggap semua yang bukan
/// Auditor sebagai Quality Manager, sehingga role baru otomatis mendapat
/// hak penuh.
enum UserRole {
  qualityManager,
  auditorInternal,
  auditee,
  admin,
  unknown;

  /// Terjemahan dari nilai yang dikirim backend (field `role`).
  ///
  /// Backend memakai 'Auditor' dan 'AuditorInternal' untuk peran yang sama.
  static UserRole fromApi(String? value) {
    switch (value) {
      case 'QualityManager':
        return UserRole.qualityManager;
      case 'Auditor':
      case 'AuditorInternal':
        return UserRole.auditorInternal;
      case 'Auditee':
        return UserRole.auditee;
      case 'Admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  /// Nama peran untuk ditampilkan ke pengguna.
  String get label {
    switch (this) {
      case UserRole.qualityManager:
        return 'Quality Manager';
      case UserRole.auditorInternal:
        return 'Auditor Internal';
      case UserRole.auditee:
        return 'Auditee';
      case UserRole.admin:
        return 'Admin';
      case UserRole.unknown:
        return '-';
    }
  }

  // ------------------------------------------------------------------ audit
  bool get canCreateAudit => this == UserRole.qualityManager;
  bool get canRunChecklist =>
      this == UserRole.qualityManager || this == UserRole.auditorInternal;

  // ---------------------------------------------------------------- finding
  bool get canCreateFinding => this != UserRole.unknown;
  bool get canEditOthersFinding => this == UserRole.qualityManager;

  // ------------------------------------------------------------------- capa
  bool get canManageCapa => this == UserRole.qualityManager;
  bool get canFillOwnCapa =>
      this == UserRole.qualityManager || this == UserRole.auditee;
  bool get canLoginOnMobile => this != UserRole.admin;
}