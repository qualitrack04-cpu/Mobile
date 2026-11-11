import 'package:equatable/equatable.dart';
import 'finding_severity.dart';

class Finding extends Equatable {
  final String id;
  final String? sessionId;
  final String title; // BARU: judul finding
  final FindingCategory category;
  final String description;
  final String clauseRef; // opsional, default kosong
  final DateTime foundAt;
  final FindingStatus status;
  final String department;
  final String reporter;
  final String reporterId;
  final bool isCapaClosed;
  final DateTime? capaClosedAt;

  const Finding({
    required this.id,
    this.sessionId,
    required this.title, // BARU
    required this.category,
    required this.description,
    this.clauseRef = '', // sebelumnya required
    required this.foundAt,
    required this.status,
    required this.department,
    required this.reporter,
    required this.reporterId,
    this.isCapaClosed = false,
    this.capaClosedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        title, // BARU
        category,
        description,
        clauseRef,
        foundAt,
        status,
        department,
        reporter,
        reporterId,
        isCapaClosed,
        capaClosedAt,
      ];
}