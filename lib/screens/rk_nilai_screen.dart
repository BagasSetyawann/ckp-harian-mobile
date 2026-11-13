import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class RkNilaiScreen extends StatefulWidget {
  const RkNilaiScreen({super.key});

  @override
  State<RkNilaiScreen> createState() => _RkNilaiScreenState();
}

class _RkNilaiScreenState extends State<RkNilaiScreen> {
  List<dynamic> _periods = [];
  int? _selectedPeriodId;
  Map<String, dynamic>? _scoreData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final periods = await ApiService.getPeriods();
      int? periodId;
      if (periods.isNotEmpty) {
        final active = periods.cast<Map<String, dynamic>>().firstWhere(
              (p) => p['is_active'] == 1 || p['status'] == 'aktif',
              orElse: () => Map<String, dynamic>.from(periods.first as Map),
            );
        periodId = active['id'] as int?;
      }
      if (!mounted) return;
      setState(() {
        _periods = periods;
        _selectedPeriodId = periodId;
      });
      await _loadScore();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat periode penilaian.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadScore() async {
    if (_selectedPeriodId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getCkpScore(periodId: _selectedPeriodId!);
      if (mounted) setState(() => _scoreData = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat nilai CKP.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadExcel() async {
    if (_selectedPeriodId == null) return;
    final uri = Uri.parse(ApiService.getExcelExportUrl(periodId: _selectedPeriodId!));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan unduhan Excel.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);

    final nilaiCkp = (_scoreData?['nilai_ckp'] as num?)?.toDouble() ?? 0.0;
    final nilaiPk = (_scoreData?['nilai_pk'] as num?)?.toDouble() ?? 0.0;
    final nilaiPerilaku = (_scoreData?['nilai_perilaku'] as num?)?.toDouble() ?? 0.0;
    final status = (_scoreData?['status'] ?? 'draft').toString();
    final catatan = (_scoreData?['catatan'] ?? '').toString().trim();
    final components = (_scoreData?['components'] as List<dynamic>?) ?? [];

    return Column(
      children: [
        if (_periods.isNotEmpty)
          PeriodSelectorBar(
            periods: _periods,
            selectedPeriodId: _selectedPeriodId,
            onChanged: (v) {
              setState(() => _selectedPeriodId = v);
              _loadScore();
            },
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadScore,
            color: p.primary,
            child: _loading
                ? Center(child: CircularProgressIndicator(color: p.primary))
                : _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          ExecutiveEmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: 'Data Tidak Tersedia',
                            subtitle: _error!,
                            buttonLabel: 'Muat Ulang',
                            onPressed: _loadScore,
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        children: [
                          // Executive Score Showcase Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [p.heroStart, p.heroEnd],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: p.heroBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'NILAI AKHIR CKP',
                                      style: AppTheme.mono(
                                        size: 11,
                                        weight: FontWeight.w600,
                                        color: const Color(0xFF94A3B8),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: AppTheme.mono(
                                          size: 10.5,
                                          weight: FontWeight.w600,
                                          color: status == 'final'
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      nilaiCkp.toStringAsFixed(1),
                                      style: AppTheme.mono(
                                        size: 42,
                                        weight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '/ 100',
                                      style: AppTheme.mono(
                                        size: 14,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Capaian Kinerja',
                                              style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              nilaiPk.toStringAsFixed(1),
                                              style: AppTheme.mono(
                                                size: 16,
                                                weight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.14)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Perilaku Kerja',
                                              style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              nilaiPerilaku.toStringAsFixed(1),
                                              style: AppTheme.mono(
                                                size: 16,
                                                weight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Components breakdown
                          HairlineCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Komponen Pembentuk Nilai',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Perhitungan otomatis mengacu rata-rata capaian kegiatan harian & perilaku.',
                                  style: TextStyle(fontSize: 12, color: p.textMuted),
                                ),
                                const SizedBox(height: 14),
                                if (components.isEmpty)
                                  Text(
                                    'Bobot komponen CKP periode ini belum dikonfigurasi.',
                                    style: TextStyle(fontSize: 12.5, color: p.textMuted),
                                  )
                                else
                                  ...components.asMap().entries.map((entry) {
                                    final c = entry.value as Map<String, dynamic>;
                                    final isLast = entry.key == components.length - 1;
                                    final kode = (c['kode'] ?? '').toString();
                                    final bobot = (c['bobot'] as num?)?.toInt() ?? 0;
                                    final nilai = (c['nilai'] as num?)?.toDouble() ?? 0.0;
                                    final weighted = (c['nilai_tertimbang'] as num?)?.toDouble() ?? 0.0;

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  kode == 'PK'
                                                      ? 'Capaian Kegiatan Harian (PK)'
                                                      : kode == 'PERILAKU'
                                                          ? 'Perilaku Kerja (BerAKHLAK)'
                                                          : kode,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: p.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              MonoPill(text: 'Bobot $bobot%'),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                'Skor ${nilai.toStringAsFixed(1)}',
                                                style: AppTheme.mono(size: 11.5, color: p.textMuted),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '+${weighted.toStringAsFixed(1)} poin',
                                                style: AppTheme.mono(
                                                  size: 12,
                                                  weight: FontWeight.w600,
                                                  color: p.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: (nilai / 100.0).clamp(0.0, 1.0),
                                              minHeight: 6,
                                              backgroundColor: p.surfaceMuted,
                                              color: kode == 'PK' ? p.primary : p.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),

                          if (catatan.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            HairlineCard(
                              padding: const EdgeInsets.all(14),
                              color: p.infoBg,
                              borderColor: p.info.withValues(alpha: 0.3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes_rounded, size: 18, color: p.info),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Catatan Penilai',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.info),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          catatan,
                                          style: TextStyle(fontSize: 12.5, color: p.textSecondary, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (_selectedPeriodId != null) ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: _downloadExcel,
                              icon: Icon(Icons.table_view_outlined, size: 18, color: p.success),
                              label: const Text('Unduh Rekap Excel (.xlsx) Periode Ini'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                            ),
                          ],
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}
