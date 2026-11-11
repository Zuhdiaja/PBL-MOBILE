import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/history/domain/entities/history_entry.dart';
import 'package:pbl_semester5/features/history/domain/entities/report_status.dart';
import 'package:pbl_semester5/features/history/domain/usecases/build_report_timeline.dart';
import 'package:pbl_semester5/features/history/domain/usecases/filter_history_entries.dart';
import 'package:pbl_semester5/features/history/domain/usecases/summarize_activity.dart';

HistoryEntry entry({
  required String id,
  required String category,
  required bool isSafe,
}) => HistoryEntry(
  id: id,
  url: '$id.example.test',
  category: category,
  confidence: 90,
  isSafe: isSafe,
  scanTime: '18 Sep 2026, 09:12 WIB',
  dayLabel: '18 September 2026',
);

void main() {
  group('FilterHistoryEntries', () {
    const filter = FilterHistoryEntries();
    final entries = [
      entry(id: '0', category: 'Phishing', isSafe: false),
      entry(id: '1', category: 'Benign', isSafe: true),
      entry(id: '2', category: 'Phishing', isSafe: false),
    ];

    test('lists the neutral option followed by every category', () {
      expect(filter.categoriesOf(entries), ['Semua', 'Phishing', 'Benign']);
    });

    test('keeps every entry for the neutral option', () {
      expect(filter(entries, filter: 'Semua').length, 3);
    });

    test('keeps only the matching category', () {
      final result = filter(entries, filter: 'Phishing');

      expect(result.map((item) => item.id), ['0', '2']);
    });

    test('returns an unmodifiable list', () {
      expect(
        () => filter(entries, filter: 'Semua').add(entries.first),
        throwsUnsupportedError,
      );
    });
  });

  group('SummarizeActivity', () {
    const summarize = SummarizeActivity();

    test('counts safe, unsafe, phishing, malware, and reports', () {
      final summary = summarize(
        entries: [
          entry(id: '0', category: 'Phishing', isSafe: false),
          entry(id: '1', category: 'Benign', isSafe: true),
          entry(id: '2', category: 'Malware', isSafe: false),
          entry(id: '3', category: 'Benign', isSafe: true),
        ],
        reportCount: 3,
      );

      expect(summary.totalCount, 4);
      expect(summary.safeCount, 2);
      expect(summary.unsafeCount, 2);
      expect(summary.phishingCount, 1);
      expect(summary.malwareCount, 1);
      expect(summary.reportCount, 3);
      expect(summary.safePercent, 50);
    });

    test('avoids dividing by zero when there is no activity', () {
      final summary = summarize(
        entries: const <HistoryEntry>[],
        reportCount: 0,
      );

      expect(summary.totalCount, 0);
      expect(summary.safeCount, 0);
      expect(summary.safePercent, 0);
    });
  });

  group('BuildReportTimeline', () {
    const buildTimeline = BuildReportTimeline();

    ReportStatus report(ReportStage stage) => ReportStatus(
      url: 'contoh.example.test',
      reportedCategory: 'Phishing',
      type: 'False Negative',
      stage: stage,
      submittedTime: '21 Sep 2026, 14:32 WIB',
    );

    test('marks the submitted stage as the first step', () {
      final timeline = buildTimeline(report(ReportStage.submitted));

      expect(timeline.steps.length, 3);
      expect(timeline.activeIndex, 0);
    });

    test('advances for reviewed and completed reports', () {
      expect(buildTimeline(report(ReportStage.review)).activeIndex, 1);
      expect(buildTimeline(report(ReportStage.completed)).activeIndex, 2);
    });

    test('replaces the last step for a rejected report', () {
      final timeline = buildTimeline(report(ReportStage.rejected));

      expect(timeline.activeIndex, 2);
      expect(timeline.steps.last, 'Ditolak');
    });

    test('labels every stage in Indonesian', () {
      expect(ReportStage.submitted.label, 'Diproses');
      expect(ReportStage.review.label, 'Ditinjau');
      expect(ReportStage.completed.label, 'Selesai');
      expect(ReportStage.rejected.label, 'Ditolak');
    });
  });
}
