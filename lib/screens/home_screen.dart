import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onTapInputCKP;
  final VoidCallback onTapRiwayat;

  const HomeScreen({
    super.key,
    required this.onTapInputCKP,
    required this.onTapRiwayat,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getPegawaiDashboard();
      if (mounted) setState(() => _dashboard = res);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat data beranda dari server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadExcel(int periodId) async {
    final uri = Uri.parse(ApiService.getExcelExportUrl(periodId: periodId));
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
    final user = ApiService.currentUser ?? {};

    if (_loading && _dashboard == null) {
      return Center(child: CircularProgressIndicator(color: p.primary));
    }

    if (_error != null && _dashboard == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ExecutiveEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Koneksi Bermasalah',
            subtitle: _error!,
            buttonLabel: 'Coba Lagi',
            onPressed: _loadData,
          ),
        ),
      );
    }

    final period = _dashboard?['period'] as Map<String, dynamic>?;
    final sudahIsi = _dashboard?['sudah_isi_hari_ini'] == true;
    final todayStr = (_dashboard?['today'] ?? '').toString();
    final todayActivities = (_dashboard?['today_activities'] as List<dynamic>?) ?? [];
    final todayAvg = (_dashboard?['today_avg_capaian'] as num?)?.toInt() ?? 0;
    final monthStats = (_dashboard?['month_stats'] as Map<String, dynamic>?) ?? {};
    final ckpScore = _dashboard?['ckp_score'] as Map<String, dynamic>?;

    final totalKegiatan = (monthStats['total_kegiatan'] as num?)?.toInt() ?? 0;
    final hariPengisian = (monthStats['hari_pengisian'] as num?)?.toInt() ?? 0;
    final hariKerja = (monthStats['hari_kerja'] as num?)?.toInt() ?? 0;
    final avgCapaian = (monthStats['avg_capaian'] as num?)?.toInt() ?? 0;
    final buktiCount = (monthStats['bukti_dukung'] as num?)?.toInt() ?? 0;
    final nilaiCkp = (ckpScore?['nilai_ckp'] as num?)?.toDouble();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: p.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Executive Hero Card (Deep Navy / Slate)
          Container(
            padding: const EdgeInsets.all(18),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        period != null ? (period['nama'] ?? 'Periode Aktif').toString() : 'Tidak Ada Periode Aktif',
                        style: AppTheme.mono(size: 11, weight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                    const Spacer(),
                    if (nilaiCkp != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'CKP ${nilaiCkp.toStringAsFixed(1)}',
                          style: AppTheme.mono(size: 11, weight: FontWeight.w600, color: const Color(0xFF38BDF8)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Halo, ${(user['nama'] ?? 'Pegawai').toString()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${user['jabatan'] ?? 'Pegawai'}${user['unit_kerja'] != null ? ' · ${user['unit_kerja']}' : ''}',
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onTapInputCKP,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Input Kegiatan Hari Ini'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Today status card
          HairlineCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: sudahIsi ? p.successBg : p.warningBg,
            borderColor: (sudahIsi ? p.success : p.warning).withValues(alpha: 0.3),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sudahIsi ? p.success : p.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sudahIsi
                            ? 'Sudah mengisi ${todayActivities.length} kegiatan hari ini'
                            : 'Belum ada catatan kegiatan hari ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sudahIsi
                            ? 'Tanggal $todayStr · Rata-rata capaian $todayAvg%'
                            : 'Segera catat aktivitas harian beserta foto/bukti GPS.',
                        style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!sudahIsi) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.onTapInputCKP,
                    style: TextButton.styleFrom(
                      foregroundColor: p.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('Isi', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2x2 Stat Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _StatCard(
                label: 'Total Kegiatan',
                value: '$totalKegiatan',
                sublabel: 'Bulan ini',
                icon: Icons.assignment_turned_in_outlined,
                accentColor: p.primary,
                accentBg: p.primaryContainer,
              ),
              _StatCard(
                label: 'Hari Mengisi',
                value: '$hariPengisian/$hariKerja',
                sublabel: 'Hari kerja',
                icon: Icons.calendar_today_outlined,
                accentColor: p.info,
                accentBg: p.infoBg,
              ),
              _StatCard(
                label: 'Rata-rata Capaian',
                value: '$avgCapaian%',
                sublabel: 'Target harian',
                icon: Icons.trending_up_rounded,
                accentColor: p.success,
                accentBg: p.successBg,
              ),
              _StatCard(
                label: 'Bukti Dukung',
                value: '$buktiCount',
                sublabel: 'File & tautan',
                icon: Icons.attach_file_rounded,
                accentColor: p.warning,
                accentBg: p.warningBg,
              ),
            ],
          ),

          if (period != null && period['id'] != null) ...[
            const SizedBox(height: 12),
            HairlineCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _downloadExcel(period['id'] as int),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.successBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.success.withValues(alpha: 0.25)),
                    ),
                    child: Icon(Icons.table_view_outlined, size: 18, color: p.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unduh Laporan Hasil Kerja (.xlsx)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.textPrimary),
                        ),
                        Text(
                          'Periode ${period['nama'] ?? ''}',
                          style: TextStyle(fontSize: 11.5, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.download_rounded, size: 19, color: p.textMuted),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          SectionHeader(
            title: 'Kegiatan Hari Ini',
            actionLabel: 'Semua Riwayat',
            onAction: widget.onTapRiwayat,
          ),
          const SizedBox(height: 10),

          if (todayActivities.isEmpty)
            ExecutiveEmptyState(
              icon: Icons.edit_calendar_outlined,
              title: 'Belum Ada Catatan Hari Ini',
              subtitle: 'Tambahkan realisasi kerja harian Anda agar progres periode tetap terjaga.',
              buttonLabel: 'Catat Kegiatan',
              onPressed: widget.onTapInputCKP,
            )
          else
            ...todayActivities.map((item) {
              final act = item as Map<String, dynamic>;
              final pct = (act['persentase_capaian'] as num?)?.toInt() ?? 0;
              final status = (act['status_kegiatan'] ?? 'selesai').toString();
              final isDone = status == 'selesai';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HairlineCard(
                  padding: const EdgeInsets.all(14),
                  onTap: widget.onTapRiwayat,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusDotBadge(
                            label: isDone ? 'Selesai' : 'Proses',
                            color: isDone ? p.success : p.warning,
                            bgColor: isDone ? p.successBg : p.warningBg,
                          ),
                          const Spacer(),
                          MonoPill(
                            text: '$pct%',
                            color: pct >= 80 ? p.success : p.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        (act['nama_kegiatan'] ?? '-').toString(),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      if (act['target'] != null && act['realisasi'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Realisasi: ${act['realisasi']} / ${act['target']} ${act['satuan'] ?? ''}',
                          style: AppTheme.mono(size: 11.5, color: p.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return HairlineCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const Spacer(),
              Text(
                sublabel,
                style: TextStyle(fontSize: 10.5, color: p.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.mono(size: 20, weight: FontWeight.w700, color: p.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
