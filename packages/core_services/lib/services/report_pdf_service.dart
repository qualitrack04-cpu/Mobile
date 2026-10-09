import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';
import 'notification_service.dart';

/// Mengunduh, menyimpan, dan membuka PDF laporan audit.
///
/// Semua method melempar [Exception] dengan pesan yang siap ditampilkan
/// jika gagal, jadi pemanggil cukup membungkusnya dengan try/catch.
class ReportPdfService {
  ReportPdfService({
    required this.apiService,
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService();

  final ApiService apiService;
  final NotificationService _notificationService;

  /// Mengambil byte PDF dari GET /api/Pdf/audit-report/{sessionId}.
  Future<List<int>> fetchBytes(String sessionId) async {
    try {
      final response = await apiService.client.get<List<int>>(
        '/api/Pdf/audit-report/$sessionId',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('The report file is empty.');
      }
      return bytes;
    } catch (e) {
      throw Exception(
        ApiService.englishErrorMessage(
          e,
          fallback: 'Failed to download the report. Please try again.',
        ),
      );
    }
  }

  /// Menyimpan PDF ke folder sementara. Tidak muncul di folder Download.
  Future<File> saveForViewing({
    required String sessionId,
    required String title,
  }) async {
    final bytes = await fetchBytes(sessionId);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${_baseName(title)}.pdf');
    return file.writeAsBytes(bytes);
  }

  /// Membuka file di pembaca PDF bawaan perangkat.
  Future<void> open(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('No app available to open the PDF.');
    }
  }

  /// Menyimpan PDF ke folder Download dan menampilkan notifikasi.
  /// Mengembalikan file yang tersimpan.
  Future<File> download({
    required String sessionId,
    required String title,
  }) async {
    final bytes = await fetchBytes(sessionId);
    final directory = await _downloadDirectory();
    final file = await _uniqueFile(directory, _baseName(title));
    await file.writeAsBytes(bytes);

    await _notificationService.showDownloadNotification(
      id: sessionId.hashCode,
      title: 'Download Complete',
      body: '${file.uri.pathSegments.last} has been downloaded',
      filePath: file.path,
    );
    return file;
  }

  Future<Directory> _downloadDirectory() async {
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) return downloads;
      final external = await getExternalStorageDirectory();
      if (external != null) return external;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Menambahkan " (1)", " (2)", dst. jika nama file sudah dipakai.
  Future<File> _uniqueFile(Directory directory, String baseName) async {
    var file = File('${directory.path}/$baseName.pdf');
    var counter = 1;
    while (await file.exists()) {
      file = File('${directory.path}/$baseName ($counter).pdf');
      counter++;
    }
    return file;
  }

  String _baseName(String title) {
    final safeTitle = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_');
    return 'AuditReport_$safeTitle';
  }
}