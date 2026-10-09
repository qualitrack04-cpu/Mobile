import 'package:core_services/core_services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State dan pemuatan data halaman dashboard.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required DashboardService service}) : _service = service;

  /// Pilihan periode pada kartu Quality Trend.
  static const List<String> trendPeriods = ['3 Month', '6 Month', '1 Year'];

  final DashboardService _service;

  bool _isFirstLoad = true;
  bool _isFetching = false;
  bool _isDisposed = false;

  AuditSummary _summary = AuditSummary(
    activeAudit: 0,
    totalCapa: 0,
    capaOpen: 0,
    capaOverdue: 0,
  );
  ComplianceScoreResponse _score = ComplianceScoreResponse(
    overallScore: 0,
    data: [],
  );
  AuditScheduleResponse _schedule = AuditScheduleResponse(
    month: DateTime.now().month,
    year: DateTime.now().year,
    data: [],
  );
  List<CompletedAuditReport> _reports = [];
  QualityTrendResponse _trend = QualityTrendResponse(
    currentScore: 0,
    previousScore: 0,
    change: 0,
    data: [],
  );
  String _trendPeriod = trendPeriods.first;

  UserRole _role = UserRole.unknown;
  String _userName = '';
  String _photoPath = '';

  /// Dinaikkan setiap refresh supaya kartu SPC ikut memuat ulang datanya.
  int spcRefreshToken = 0;

  /// True hanya pada pemuatan pertama, dipakai untuk efek skeleton.
  /// Saat refresh, data lama tetap tampil.
  bool get isLoading => _isFirstLoad;

  AuditSummary get summary => _summary;
  ComplianceScoreResponse get score => _score;
  AuditScheduleResponse get schedule => _schedule;
  List<CompletedAuditReport> get reports => _reports;
  QualityTrendResponse get trend => _trend;
  String get trendPeriod => _trendPeriod;

  UserRole get role => _role;
  String get userName => _userName;
  String get photoPath => _photoPath;

  int get _trendMonths {
    switch (_trendPeriod) {
      case '6 Month':
        return 6;
      case '1 Year':
        return 12;
      case '3 Month':
      default:
        return 3;
    }
  }

  /// Memuat ulang seluruh data dashboard. Dipanggil saat halaman dibuka
  /// dan saat pull-to-refresh.
  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    spcRefreshToken++;
    notifyListeners();

    try {
      final now = DateTime.now();
      final results = await (
        _service.getAuditSummary(),
        _service.getComplianceScores(),
        _service.getAuditSchedule(month: now.month, year: now.year),
        _service.getCompletedReports(),
        _service.getQualityTrend(months: _trendMonths),
      ).wait;

      _summary = results.$1;
      _score = results.$2;
      _schedule = results.$3;
      _reports = results.$4;
      _trend = results.$5;
    } finally {
      _isFetching = false;
      _isFirstLoad = false;
      notifyListeners();
    }
  }

  /// Mengganti periode tren, lalu memuat ulang tren saja.
  Future<void> changeTrendPeriod(String period) async {
    if (period == _trendPeriod) return;
    _trendPeriod = period;
    notifyListeners();

    final trend = await _service.getQualityTrend(months: _trendMonths);
    // Abaikan hasil lama jika periode sudah diganti lagi saat menunggu.
    if (_trendPeriod != period) return;
    _trend = trend;
    notifyListeners();
  }

  /// Membaca nama, peran, dan foto pengguna dari penyimpanan lokal.
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _role = UserRole.fromApi(prefs.getString('user_role'));
    _userName = prefs.getString('user_name') ?? '';
    _photoPath = prefs.getString('user_photo') ?? '';
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // Hindari error jika pemuatan selesai setelah halaman ditutup.
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}