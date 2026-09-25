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

  /// Role tidak dikenal, misalnya karena backend menambah role baru yang
  /// belum ditangani mobile. Sengaja tanpa hak akses apa pun.
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
      case UserRole.unknown:
        return '-';
    }
  }

  // ------------------------------------------------------------------ audit

  /// Membuat, mengubah, dan menghapus audit plan.
  bool get canCreateAudit => this == UserRole.qualityManager;

  /// Membuka dan mengisi checklist audit.
  bool get canRunChecklist =>
      this == UserRole.qualityManager || this == UserRole.auditorInternal;

  // ---------------------------------------------------------------- finding

  /// Membuat finding baru.
  bool get canCreateFinding => this != UserRole.unknown;

  /// Mengubah finding milik orang lain.
  ///
  /// Role lain tetap boleh mengubah finding yang dia laporkan sendiri;
  /// pemeriksaan itu dilakukan di halaman dengan membandingkan pelapornya.
  bool get canEditOthersFinding => this == UserRole.qualityManager;

  // ------------------------------------------------------------------- capa

  /// Membuat CAPA, menunjuk PIC, dan mengubah status CAPA milik siapa pun.
  bool get canManageCapa => this == UserRole.qualityManager;

  /// Mengerjakan CAPA yang menjadi tugasnya sendiri.
  bool get canFillOwnCapa =>
      this == UserRole.qualityManager || this == UserRole.auditee;
}