import '../../../../widgets/loading_states.dart';
import '../../../../widgets/load_view.dart';

import 'package:flutter/material.dart';

import '../../../../widgets/scan_components.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/history_entry.dart';
import '../controllers/history_controller.dart';
import '../widgets/history_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller, this.onOpenDetail});

  final HistoryController controller;

  /// Navigation is wired by the shell; this feature stays on its own data.
  final ValueChanged<HistoryEntry>? onOpenDetail;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showCategories = false;
  late final _search = TextEditingController(text: widget.controller.query);
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LoadView(
    controller: widget.controller,
    kind: 'history',
    subpage: false,
    loadingBuilder: (context) => _page(context, pending: true),
    errorBuilder: (context) => _page(context),
    builder: (context) => _page(context),
  );

  Widget _page(BuildContext context, {bool pending = false}) {
    final controller = widget.controller;
    return ScanPage(
      children: [
        const Text('Riwayat pindai', style: pageTitleStyle),
        const SizedBox(height: 20),
        const Text(
          'Cari tautan',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _search,
          onChanged: controller.setQuery,
          decoration: InputDecoration(
            hintText: 'Cari URL atau domain…',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.colors.muted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final scope in ['Semua', 'Aman', 'Perlu perhatian'])
              Expanded(
                child: HistoryFilterChip(
                  label: scope,
                  selected: controller.scope == scope,
                  onTap: () => controller.selectScope(scope),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Kategori tautan',
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: controller.filter,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.layers_outlined, size: 19),
          ),
          isExpanded: true,
          items: controller.filters
              .map(
                (label) => DropdownMenuItem(
                  value: label,
                  child: Text(
                    label == 'Semua' ? 'Semua kategori' : categoryLabel(label),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.selectFilter(value);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                pending
                    ? 'Memuat riwayat…'
                    : '${controller.visibleEntries.length} hasil',
                style: TextStyle(fontSize: 11, color: context.colors.muted),
              ),
            ),
            TextButton(
              onPressed: () =>
                  setState(() => _showCategories = !_showCategories),
              child: const Text(
                'Arti kategori',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
        if (_showCategories)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in const {
                  'Aman': 'Tidak ada pola berisiko pada hasil contoh.',
                  'Phishing':
                      'Tautan yang menyamar untuk mengambil data pribadi.',
                  'Malware': 'Tautan yang berpotensi menyebarkan perangkat lunak berbahaya.',
                  'Spam': 'Tautan promosi atau pesan yang tidak diinginkan.',
                  'Perusakan situs':
                      'Tautan ke situs yang tampilannya diubah tanpa izin.',
                  'Eksploitasi':
                      'Tautan yang berpotensi memanfaatkan celah keamanan.',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.key}. ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: item.value),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.muted,
                        height: 1.6,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (pending)
          const LoadingRows(count: 3, label: 'Memuat riwayat pindai')
        else if (controller.loadError != null)
          LoadFailure(message: controller.loadError!, onRetry: controller.load)
        else if (controller.visibleEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: InfoNote(
              'Tidak ada tautan yang cocok. Coba kata kunci atau kategori lain.',
            ),
          )
        else
          ..._buildGroupedItems(controller.visibleEntries),
        const SizedBox(height: 20),
        const InfoNote(
          'Data contoh. Riwayat pindai belum tersimpan di perangkat.',
        ),
      ],
    );
  }

  List<Widget> _buildGroupedItems(List<HistoryEntry> entries) {
    final children = <Widget>[];
    String? currentDay;

    for (final entry in entries) {
      if (entry.dayLabel != currentDay) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 20));
        currentDay = entry.dayLabel;
        children
          ..add(HistoryDayLabel(entry.dayLabel))
          ..add(const SizedBox(height: 8));
      }
      children
        ..add(HistoryRow(entry: entry, onOpenDetail: widget.onOpenDetail))
        ..add(const SizedBox(height: 6));
    }
    return children;
  }
}
