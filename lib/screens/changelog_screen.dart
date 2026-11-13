import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  static const List<Map<String, dynamic>> _fallbackChangelogs = [
    {
      'versi': 'v1.3.0',
      'judul': 'Fitur Changelog Publik & Penghapusan Verifikasi KPA',
      'tanggal': '2026-11-12',
      'tipe': 'major',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Web & Mobile',
          'deskripsi':
              'Menambahkan menu dan halaman Changelog (Riwayat Pembaruan Sistem) yang dapat dilihat oleh seluruh pengguna (KPA, Kasubbag, dan Pegawai).',
        },
        {
          'kategori': 'Perubahan',
          'platform': 'Web, Mobile & Backend',
          'deskripsi':
              'Menghapus alur dan status verifikasi kegiatan harian oleh KPA sehingga pencatatan kegiatan langsung tercatat tanpa menunggu verifikasi KPA.',
        },
      ],
    },
    {
      'versi': 'v1.2.0',
      'judul': 'Kamera Geotag GPS & Timestamp, Input Web & Mobile, Export Periode & Hold RK',
      'tanggal': '2026-11-12',
      'tipe': 'major',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Mobile',
          'deskripsi':
              'Kamera bukti dukung pada SI-CKP Mobile otomatis menangkap koordinat GPS & Timestamp lalu mencetak watermark langsung pada foto.',
        },
        {
          'kategori': 'Fitur Baru',
          'platform': 'Web & Mobile',
          'deskripsi':
              'Fitur Download Hasil Kerja per Periode dalam format Excel (.xlsx) dan PDF tersedia langsung.',
        },
        {
          'kategori': 'Perubahan',
          'platform': 'Web, Mobile & Backend',
          'deskripsi':
              'Menonaktifkan sementara (hold) fitur Rencana Kinerja (RK); perhitungan nilai mengacu rata-rata capaian kegiatan harian.',
        },
      ],
    },
    {
      'versi': 'v1.1.0',
      'judul': 'Peluncuran Aplikasi SI-CKP Mobile (Android) & Integrasi Cloud',
      'tanggal': '2026-11-12',
      'tipe': 'major',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Mobile',
          'deskripsi':
              'Rilis perdana aplikasi SI-CKP Mobile Android dengan fitur Beranda, Input Kegiatan, Bukti Dukung, Riwayat, dan Nilai CKP.',
        },
      ],
    },
    {
      'versi': 'v1.0.0',
      'judul': 'Rilis Awal Sistem Informasi CKP Harian (SI-CKP)',
      'tanggal': '2026-11-02',
      'tipe': 'major',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Web & Backend',
          'deskripsi':
              'Peluncuran awal SI-CKP meliputi pencatatan kegiatan harian pegawai, bukti dukung, kalender pengisian, penilaian perilaku, dan nilai CKP.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await ApiService.getChangelogs();
      if (mounted && rows.isNotEmpty) {
        setState(() {
          _items = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _fromCache = false;
        });
      } else if (mounted) {
        setState(() {
          _items = _fallbackChangelogs;
          _fromCache = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = _fallbackChangelogs;
          _fromCache = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  (Color fg, Color bg) _categoryColors(AppPalette p, String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('fitur')) return (p.success, p.successBg);
    if (k.contains('perubahan')) return (p.info, p.infoBg);
    if (k.contains('perbaikan')) return (p.warning, p.warningBg);
    return (p.textSecondary, p.surfaceMuted);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pembaruan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: p.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Executive Header Banner
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
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF38BDF8), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Changelog SI-CKP',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _items.isNotEmpty ? (_items.first['versi'] ?? 'v1.3.0').toString() : 'v1.3.0',
                                style: AppTheme.mono(size: 11, weight: FontWeight.w600, color: const Color(0xFF38BDF8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _fromCache
                              ? 'Menampilkan catatan rilis lokal aplikasi.'
                              : 'Catatan rilis resmi Web, Mobile & Backend.',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.78)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_loading && _items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(color: p.primary)),
              )
            else
              ...List.generate(_items.length, (idx) {
                final rel = _items[idx];
                final changes = (rel['perubahan'] as List<dynamic>?) ?? [];
                final isLatest = idx == 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HairlineCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                            border: Border(bottom: BorderSide(color: p.border)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isLatest ? p.primaryDeep : p.surface,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(color: isLatest ? p.heroBorder : p.borderStrong),
                                    ),
                                    child: Text(
                                      (rel['versi'] ?? '').toString(),
                                      style: AppTheme.mono(
                                        size: 11.5,
                                        weight: FontWeight.w600,
                                        color: isLatest ? Colors.white : p.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (isLatest) ...[
                                    const SizedBox(width: 8),
                                    StatusDotBadge(label: 'Terbaru', color: p.success, bgColor: p.successBg),
                                  ],
                                  const Spacer(),
                                  Text(
                                    (rel['tanggal'] ?? '').toString(),
                                    style: AppTheme.mono(size: 11, color: p.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (rel['judul'] ?? '').toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: p.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: changes.asMap().entries.map((entry) {
                              final c = entry.value as Map<String, dynamic>;
                              final isLast = entry.key == changes.length - 1;
                              final kategori = (c['kategori'] ?? 'Info').toString();
                              final platform = (c['platform'] ?? '').toString();
                              final (fg, bg) = _categoryColors(p, kategori);

                              return Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        StatusDotBadge(label: kategori, color: fg, bgColor: bg, showDot: false),
                                        if (platform.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          MonoPill(text: platform),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      (c['deskripsi'] ?? '').toString(),
                                      style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.45),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
