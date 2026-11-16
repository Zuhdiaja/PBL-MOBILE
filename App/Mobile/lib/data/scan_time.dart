/// Formats API timestamps in Indonesian time.
///
/// The server stores UTC; every screen shows WIB (UTC+7).
class ScanTime {
  ScanTime._();

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const _longMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static DateTime? toWib(DateTime? value) =>
      value?.toUtc().add(const Duration(hours: 7));

  /// e.g. `11 Nov 2026, 16:05 WIB`.
  static String stamp(DateTime? value) {
    final wib = toWib(value);
    if (wib == null) return '-';
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    return '${wib.day} ${_shortMonths[wib.month - 1]} ${wib.year}, $hour:$minute WIB';
  }

  /// e.g. `11 November 2026`, used to group the history list by day.
  static String dayLabel(DateTime? value) {
    final wib = toWib(value);
    if (wib == null) return 'Tanpa tanggal';
    return '${wib.day} ${_longMonths[wib.month - 1]} ${wib.year}';
  }
}
