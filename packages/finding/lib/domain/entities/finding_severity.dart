import 'package:equatable/equatable.dart';

/// Kategori finding dari backend. Admin bisa menambah kategori,
/// jadi ini data (id + nama), bukan enum.
class FindingCategory extends Equatable {
  final String id;
  final String name;

  const FindingCategory({required this.id, required this.name});

  /// "MajorNC" -> "Major NC", "OFI" tetap "OFI"
  String get label => name.replaceAllMapped(
        RegExp(r'(?<=[a-z])(?=[A-Z])'),
        (_) => ' ',
      );

  @override
  List<Object?> get props => [id];
}

enum FindingStatus {
  open,
  inProgress,
  closed;

  static FindingStatus fromString(String value) {
    switch (value) {
      case 'Open':
        return FindingStatus.open;
      case 'InProgress':
        return FindingStatus.inProgress;
      case 'Closed':
        return FindingStatus.closed;
      default:
        return FindingStatus.open;
    }
  }

  String toBackendString() {
    switch (this) {
      case FindingStatus.open:
        return 'Open';
      case FindingStatus.inProgress:
        return 'InProgress';
      case FindingStatus.closed:
        return 'Closed';
    }
  }
}