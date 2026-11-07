import 'api_service.dart';

/// Satu template checklist dari GET /api/checklists.
/// Dipakai untuk tahu pasangan ISO + department mana yang punya checklist.
class ChecklistTemplateInfo {
  const ChecklistTemplateInfo({
    required this.id,
    required this.title,
    required this.standard,
    required this.department,
  });

  final String id;
  final String title;

  /// Field `isoStandardName`, mis. "ISO14001".
  final String standard;

  /// Field `departmentName`, mis. "Production".
  final String department;

  /// "ISO 14001:2015" dan "ISO14001" sama-sama jadi "iso14001".
  static String standardKey(String raw) {
    final text = raw.trim();
    final m = RegExp(r'^([A-Za-z]+)[\s_-]*(\d+)').firstMatch(text);
    if (m != null) return '${m[1]}${m[2]}'.toLowerCase();
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// "Produksi" dan "Production" sama-sama jadi "production".
  static String departmentKey(String raw) {
    final k = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    switch (k) {
      case 'produksi':
        return 'production';
      case 'qc':
      case 'qualitymanager':
        return 'qualitycontrol';
      default:
        return k;
    }
  }

  bool matchesStandard(String raw) => standardKey(raw) == standardKey(standard);

  bool matchesDepartment(String raw) =>
      departmentKey(raw) == departmentKey(department);

  bool matches(String iso, String dept) =>
      matchesStandard(iso) && matchesDepartment(dept);

  factory ChecklistTemplateInfo.fromJson(Map<String, dynamic> json) {
    return ChecklistTemplateInfo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      standard:
          (json['isoStandardName'] ?? json['standard'] ?? '').toString().trim(),
      department:
          (json['departmentName'] ?? json['department'] ?? '')
              .toString()
              .trim(),
    );
  }

  /// Template yang ISO atau department-nya kosong dilewati.
  static Future<List<ChecklistTemplateInfo>> fetchAll(ApiService api) async {
    final res = await api.client.get('/api/checklists');
    final body = res.data;
    final raw =
        body is List
            ? body
            : (body is Map ? (body['data'] as List? ?? []) : <dynamic>[]);

    return raw
        .whereType<Map>()
        .map((e) => ChecklistTemplateInfo.fromJson(Map<String, dynamic>.from(e)))
        .where((t) => t.id.isNotEmpty && t.standard.isNotEmpty && t.department.isNotEmpty)
        .toList();
  }
}