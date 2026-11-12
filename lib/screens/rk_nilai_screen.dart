import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class RkNilaiScreen extends StatefulWidget {
  const RkNilaiScreen({super.key});

  @override
  State<RkNilaiScreen> createState() => _RkNilaiScreenState();
}

class _RkNilaiScreenState extends State<RkNilaiScreen> {
  List<dynamic> _periods = [];
  Map<String, dynamic>? _ckpData;
  int? _selectedPeriodId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final periods = await ApiService.getPeriods();
      _periods = periods;
      if (periods.isNotEmpty) {
        Map<String, dynamic>? active;
        for (final item in periods) {
          if (item is Map<String, dynamic> && (item['is_active'] == 1 || item['status'] == 'aktif')) {
            active = item;
            break;
          }
        }
        active ??= periods.first as Map<String, dynamic>;
        _selectedPeriodId = (active['id'] as num?)?.toInt();
      }
      await _loadData();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadData() async {
    if (_selectedPeriodId == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.getCkpScore(periodId: _selectedPeriodId!);
      if (mounted) {
        setState(() {
          _ckpData = res;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nilaiCkp = (_ckpData?['nilai_ckp'] ?? 0).toDouble();
    final nilaiPk = _ckpData?['nilai_pk'] ?? 0;
    final nilaiPerilaku = _ckpData?['nilai_perilaku'] ?? 0;
    final status = _ckpData?['status'] ?? 'draft';
    final catatan = _ckpData?['catatan']?.toString() ?? '';

    return Column(
      children: [
        // Period Selector
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: DropdownButtonFormField<int>(
            value: _selectedPeriodId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Periode Penilaian & Laporan',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            items: _periods.map((p) {
              return DropdownMenuItem<int>(
                value: p['id'] as int,
                child: Text(p['nama'].toString(), style: const TextStyle(fontSize: 13.5)),
              );
            }).toList(),
            onChanged: (v) {
              setState(() => _selectedPeriodId = v);
              _loadData();
            },
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Score Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF075985)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Nilai CKP Bulanan',
                                  style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 13),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status == 'final' ? '✓ Final' : '⏳ Draft',
                                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$nilaiCkp',
                              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nilai Capaian (PK)', style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11.5)),
                                      Text('$nilaiPk', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nilai Perilaku', style: TextStyle(color: Color(0xFFBAE6FD), fontSize: 11.5)),
                                      Text('$nilaiPerilaku', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (catatan.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Catatan KPA: $catatan',
                                style: const TextStyle(color: Color(0xFFE0F2FE), fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Download Hasil Kerja per Periode Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.download_for_offline_rounded, color: Color(0xFF059669), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Unduh Hasil Kerja Periode Ini',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Unduh laporan lengkap hasil kerja harian Anda beserta informasi bukti dukung dan nilai CKP dalam format Excel (.xlsx).',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: _selectedPeriodId == null
                                    ? null
                                    : () {
                                        final url = ApiService.getExcelExportUrl(periodId: _selectedPeriodId!);
                                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      },
                                icon: const Icon(Icons.table_view_rounded),
                                label: const Text(
                                  'Download Hasil Kerja (.xlsx)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
