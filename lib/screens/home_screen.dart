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
  bool _reminderDismissed = false;

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
          // KASI JADI Hero Card (Biru Elektrik + Neo-Brutalism)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.heroStart, p.heroEnd],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  offset: const Offset(4, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(36),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withAlpha(90), width: 1.5),
                              ),
                              child: Text(
                                period != null
                                    ? (period['nama'] ?? 'Periode Aktif').toString()
                                    : 'Tidak Ada Periode Aktif',
                                style: AppTheme.mono(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (nilaiCkp != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4D8),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                                ),
                                child: Text(
                                  'CKP ${nilaiCkp.toStringAsFixed(1)}',
                                  style: AppTheme.mono(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Halo, ${(user['nama'] ?? 'Pegawai').toString()}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${user['jabatan'] ?? 'Pegawai'}${user['unit_kerja'] != null ? ' · ${user['unit_kerja']}' : ''}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withAlpha(215),
                          ),
                        ),
                        const SizedBox(height: 16),
                        KjNeoButton(
                          label: sudahIsi ? 'Tambah Kegiatan' : 'GAS ISI! Kegiatan',
                          icon: Icons.add_rounded,
                          variant: KjButtonVariant.orange,
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onPressed: widget.onTapInputCKP,
                        ),
                      ],
                    ),
                  ),
                  const KjTenunStrip(
                    height: 8,
                    opacity: 0.26,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          if (!sudahIsi && !_reminderDismissed) ...[
            const SizedBox(height: 12),
            KjReminderBanner(
              message: 'Jangan lupa spill kerjaan hari ini, Jo!',
              ctaLabel: 'GAS ISI!',
              onTapCta: widget.onTapInputCKP,
              onDismiss: () => setState(() => _reminderDismissed = true),
            ),
          ],

          const SizedBox(height: 12),

          // Today status card
          HairlineCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: sudahIsi ? p.tealBg : p.orangeBg,
            borderColor: p.border,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: sudahIsi ? p.teal : p.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border, width: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sudahIsi
                            ? 'BERES! ${todayActivities.length} kegiatan hari ini'
                            : 'Belum ada catatan kegiatan hari ini',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sudahIsi
                            ? 'Tanggal $todayStr · Rata-rata capaian $todayAvg%'
                            : 'Catat aktivitas harian + foto geotag GPS sekarang.',
                        style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (sudahIsi)
                  StatusDotBadge(
                    label: 'BERES!',
                    color: p.success,
                    bgColor: p.surface,
                    showDot: false,
                  )
                else ...[
                  const SizedBox(width: 8),
                  KjNeoButton(
                    label: 'GAS ISI!',
                    variant: KjButtonVariant.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    onPressed: widget.onTapInputCKP,
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
              color: p.tealBg,
              onTap: () => _downloadExcel(period['id'] as int),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: p.teal,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border, width: 1.5),
                    ),
                    child: const Icon(Icons.table_view_rounded, size: 19, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unduh Laporan Hasil Kerja (.xlsx)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: p.textPrimary),
                        ),
                        Text(
                          'Periode ${period['nama'] ?? ''}',
                          style: TextStyle(fontSize: 11.5, color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.border, width: 1.5),
                    ),
                    child: Icon(Icons.download_rounded, size: 17, color: p.textPrimary),
                  ),
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
              icon: Icons.edit_calendar_rounded,
              title: 'Belum Ada Catatan Hari Ini',
              subtitle: 'Spill realisasi kerja harianmu sekarang agar progres periode tetap terjaga.',
              buttonLabel: 'GAS ISI!',
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
                            label: isDone ? 'BERES!' : 'Proses',
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: p.border, width: 1.5),
                ),
                child: Icon(icon, size: 16, color: accentColor),
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
