import 'app_colors.dart';
import 'package:flutter/material.dart';

/// Nama dan warna departemen untuk tampilan dashboard.
abstract final class DepartmentStyle {
  /// Departemen standar, berurutan seperti pada legend.
  static const List<String> standard = [
    'Production',
    'Packaging',
    'Warehouse',
    'Quality Control',
  ];

  /// Menyeragamkan nama dari backend ke nama tampilan.
  ///
  /// Nama yang tidak dikenal dikembalikan apa adanya.
  static String normalize(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'produksi':
      case 'production':
        return 'Production';
      case 'qc':
      case 'quality control':
      case 'quality manager':
        return 'Quality Control';
      case 'packaging':
        return 'Packaging';
      case 'warehouse':
        return 'Warehouse';
      default:
        return raw;
    }
  }

  /// Warna departemen. Nama boleh mentah, akan dinormalisasi dulu.
  static Color colorOf(String raw) {
    switch (normalize(raw)) {
      case 'Production':
        return AppColors.deptProduction;
      case 'Packaging':
        return AppColors.deptPackaging;
      case 'Warehouse':
        return AppColors.deptWarehouse;
      case 'Quality Control':
        return AppColors.deptQualityControl;
      default:
        return AppColors.primary;
    }
  }
}