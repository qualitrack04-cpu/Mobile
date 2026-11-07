/// Zona waktu dan format tanggal sistem. Nilainya dari backend
/// (/api/system-config/timezone dan /date-format), bisa diubah admin.
abstract final class AppClock {
  static const String _defaultFormat = 'yyyy-MM-dd';

  /// Null berarti belum ada config: pakai zona waktu perangkat.
  static Duration? _offset;
  static String _zoneLabel = '';
  static String _dateFormat = _defaultFormat;

  static Duration get _activeOffset => _offset ?? DateTime.now().timeZoneOffset;

  /// Dipanggil setiap config dari backend dimuat. Parameter null = tidak diubah.
  static void configure({
    double? utcOffsetHours,
    String? zoneLabel,
    String? dateFormat,
  }) {
    if (utcOffsetHours != null) {
      _offset = Duration(minutes: (utcOffsetHours * 60).round());
    }
    if (zoneLabel != null) _zoneLabel = zoneLabel.trim();
    if (dateFormat != null && _isValidFormat(dateFormat)) {
      _dateFormat = dateFormat.trim();
    }
  }

  /// Format harus punya tahun, bulan, dan hari. Kalau tidak, diabaikan.
  static bool _isValidFormat(String f) {
    final lower = f.toLowerCase();
    return lower.contains('y') && lower.contains('d') && (lower.contains('m'));
  }

  static String get zoneLabel => _zoneLabel;

  /// Parse timestamp dari backend sebagai UTC. String tanpa zona
  /// (mis. "2026-10-27T05:34:45.709716") dianggap UTC, bukan waktu perangkat.
  /// String tanggal saja ("2026-11-15") dikembalikan apa adanya.
  static DateTime parseUtc(String raw) {
    final text = raw.trim();
    if (!text.contains(RegExp(r'[T ]'))) return DateTime.parse(text);
    final hasZone = RegExp(r'([zZ]|[+-]\d{2}:?\d{2})$').hasMatch(text);
    return DateTime.parse(hasZone ? text : '${text}Z').toUtc();
  }

  /// Menggeser ke zona sistem. Hasilnya bertanda UTC, tapi field-nya
  /// (day, hour, dst.) sudah berisi jam dinding zona sistem.
  static DateTime toSystem(DateTime value) => value.toUtc().add(_activeOffset);

  /// Tanggal sesuai format admin.
  ///
  /// [convert] true untuk timestamp (createdAt, foundAt, analyzedAt).
  /// Pakai false untuk tanggal kalender (jadwal audit, deadline, hasil
  /// date picker), supaya harinya tidak bergeser karena zona waktu.
  static String formatDate(DateTime value, {bool convert = true}) =>
      _apply(_dateFormat, convert ? toSystem(value) : value);

  /// Jam 24 jam, contoh "14:05".
  static String formatTime(DateTime value, {bool convert = true}) {
    final d = convert ? toSystem(value) : value;
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// Tanggal + jam. [withZone] menambahkan label seperti "WIB".
  static String formatDateTime(
    DateTime value, {
    bool convert = true,
    bool withZone = false,
  }) {
    final text =
        '${formatDate(value, convert: convert)} '
        '${formatTime(value, convert: convert)}';
    return withZone && _zoneLabel.isNotEmpty ? '$text $_zoneLabel' : text;
  }

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static final RegExp _token = RegExp(
    r'month|[yY]+|[mM]+|[dD]+',
    caseSensitive: false,
  );

  static String _apply(String pattern, DateTime d) {
    return pattern.replaceAllMapped(_token, (m) {
      final text = m[0]!;
      final lower = text.toLowerCase();
      final n = text.length;

      if (lower == 'month') return _months[d.month - 1];

      switch (lower[0]) {
        case 'y':
          return n <= 2
              ? _two(d.year % 100)
              : d.year.toString().padLeft(4, '0');
        case 'm':
          if (n >= 4) return _months[d.month - 1];
          if (n == 3) return _months[d.month - 1].substring(0, 3);
          return n == 2 ? _two(d.month) : '${d.month}';
        case 'd':
          return n >= 2 ? _two(d.day) : '${d.day}';
      }
      return text;
    });
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
