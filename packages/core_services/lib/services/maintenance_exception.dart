class MaintenanceException implements Exception {
  final String message;

  MaintenanceException({this.message = 'System is under maintenance'});

  @override
  String toString() => message;
}
