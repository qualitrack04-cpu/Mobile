enum FindingCategory {
  majorNC,
  minorNC,
  observation,
  ofi;

  static FindingCategory fromString(String value) {
    switch (value) {
      case 'MajorNC':
        return FindingCategory.majorNC;
      case 'MinorNC':
        return FindingCategory.minorNC;
      case 'Observation':
        return FindingCategory.observation;
      case 'OFI':
        return FindingCategory.ofi;
      default:
        throw Exception('Unknown finding category: $value');
    }
  }

  String toBackendString() {
    switch (this) {
      case FindingCategory.majorNC:
        return 'MajorNC';
      case FindingCategory.minorNC:
        return 'MinorNC';
      case FindingCategory.observation:
        return 'Observation';
      case FindingCategory.ofi:
        return 'OFI';
    }
  }
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