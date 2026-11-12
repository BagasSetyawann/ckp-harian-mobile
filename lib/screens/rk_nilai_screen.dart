import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RkNilaiScreen extends StatefulWidget {
  const RkNilaiScreen({super.key});

  @override
  State<RkNilaiScreen> createState() => _RkNilaiScreenState();
}

class _RkNilaiScreenState extends State<RkNilaiScreen> {
  List<dynamic> _periods = [];
  List<dynamic> _plans = [];
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
      final results = await Future.wait([
        ApiService.getPerformancePlans(periodId: _selectedPeriodId),
        ApiService.getCkpScore(periodId: _selectedPeriodId!),
      ]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<dynamic>;
          _ckpData = results[1] as Map<String, dynamic>;
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
              labelText: 'Periode Penilaian',
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Daftar Rencana Kinerja (RK)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 10),

                      if (_plans.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text('Belum ada Rencana Kinerja pada periode ini.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ..._plans.map((p) {
                          final capaian = (p['persentase_capaian'] ?? 0).toDouble();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p['kode']?.toString() ?? 'RK',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                      ),
                                    ),
                                    Text(
                                      'Bobot ${p['bobot'] ?? 0}%',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  p['nama']?.toString() ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                ),
                                if (p['indikator'] != null && p['indikator'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Indikator: ${p['indikator']}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: (capaian / 100).clamp(0.0, 1.0),
                                    minHeight: 7,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      capaian >= 100 ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Realisasi: ${p['total_realisasi'] ?? 0} / ${p['target']} ${p['satuan']}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    Text(
                                      '${capaian.toInt()}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0284C7)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

