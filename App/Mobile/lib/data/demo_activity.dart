import 'package:flutter/material.dart';

class ReportItem {
  const ReportItem({
    required this.url,
    required this.reportedCategory,
    required this.type,
    required this.submittedTime,
    required this.status,
    this.notes,
  });

  final String url;
  final String reportedCategory;

  /// 'False Positive' atau 'False Negative'.
  final String type;

  /// 'Diproses', 'Ditinjau', atau 'Selesai'.
  final String status;
  final String submittedTime;
  final String? notes;
}

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.group,
    required this.icon,
    this.unread = false,
  });

  final String title;
  final String body;
  final String time;

  /// 'Hari ini' atau 'Sebelumnya'.
  final String group;
  final IconData icon;
  final bool unread;
}

final List<ReportItem> demoReports = [
  const ReportItem(
    url: 'docs.example.com',
    reportedCategory: 'Benign',
    type: 'False Positive',
    status: 'Selesai',
    submittedTime: '20 Sep 2026, 10:05 WIB',
    notes: 'Portal berita resmi, bukan situs phishing.',
  ),
  const ReportItem(
    url: 'cashback-klaim.example.com',
    reportedCategory: 'Phishing',
    type: 'False Negative',
    status: 'Ditinjau',
    submittedTime: '21 Sep 2026, 14:32 WIB',
    notes: 'Tautan terindikasi mengambil data login pengguna.',
  ),
  const ReportItem(
    url: 'track-paket-resi.example.com',
    reportedCategory: 'Malware',
    type: 'False Negative',
    status: 'Diproses',
    submittedTime: '23 Sep 2026, 08:17 WIB',
  ),
];

final List<NotificationItem> demoNotifications = [
  const NotificationItem(
    title: 'Laporan selesai ditinjau',
    body: 'Laporan untuk docs.example.com telah ditinjau. Status diperbarui menjadi Selesai.',
    time: '09:15',
    group: 'Hari ini',
    icon: Icons.flag_rounded,
    unread: true,
  ),
  const NotificationItem(
    title: 'URL berbahaya terdeteksi',
    body: 'bank-login.example.test terdeteksi sebagai Phishing dengan confidence 96%.',
    time: '09:42',
    group: 'Hari ini',
    icon: Icons.warning_amber_rounded,
    unread: true,
  ),
  const NotificationItem(
    title: 'Laporan sedang ditinjau',
    body: 'Laporan untuk cashback-klaim.example.com sedang ditinjau oleh tim kami.',
    time: 'Kemarin, 14:32',
    group: 'Sebelumnya',
    icon: Icons.flag_rounded,
  ),
  const NotificationItem(
    title: 'Scan selesai',
    body: '8 URL selesai diperiksa. Buka halaman Statistik untuk melihat ringkasannya.',
    time: 'Kemarin, 09:42',
    group: 'Sebelumnya',
    icon: Icons.verified_user_outlined,
  ),
  const NotificationItem(
    title: 'Laporan diterima',
    body: 'Laporan untuk track-paket-resi.example.com sedang diproses.',
    time: '23 Sep, 08:17',
    group: 'Sebelumnya',
    icon: Icons.flag_rounded,
  ),
];
