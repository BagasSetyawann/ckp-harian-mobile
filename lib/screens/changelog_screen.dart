import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Web & Mobile',
          'deskripsi':
              'Menambahkan menu dan halaman Changelog (Riwayat Pembaruan Sistem) yang dapat dilihat oleh seluruh pengguna (KPA, Kasubbag, dan Pegawai/Anggota).'
        },
        {
          'kategori': 'Perubahan',
          'platform': 'Web, Mobile & Backend',
          'deskripsi':
              'Menghapus alur dan status verifikasi kegiatan harian oleh KPA di seluruh halaman (Dashboard, Kegiatan Harian, Kalender, Laporan Cetak/Excel, dan Aplikasi Mobile) sehingga pencatatan kegiatan langsung tercatat tanpa menunggu verifikasi KPA.'
        },
      ],
    },
    {
      'versi': 'v1.2.0',
      'judul': 'Kamera Geotag GPS & Timestamp, Input Web & Mobile, Export Periode & Hold RK',
      'tanggal': '2026-11-12',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Mobile',
          'deskripsi':
              'Kamera bukti dukung pada SI-CKP Mobile otomatis menangkap titik koordinat GPS (Latitude, Longitude, Akurasi) dan Timestamp, lalu mencetak watermark langsung pada foto serta menyimpan metadatanya.'
        },
        {
          'kategori': 'Fitur Baru',
          'platform': 'Web & Mobile',
          'deskripsi':
              'Fitur Download Hasil Kerja per Periode dalam format Excel (.xlsx) dan Cetak/PDF tersedia langsung di Dashboard, Kegiatan Harian, Nilai CKP, serta Aplikasi Mobile.'
        },
        {
          'kategori': 'Perubahan',
          'platform': 'Web',
          'deskripsi':
              'Mengaktifkan kembali fitur tambah, edit, dan hapus kegiatan harian serta unggah bukti dukung pada Website sehingga pegawai dapat menginput dari Web maupun Mobile.'
        },
        {
          'kategori': 'Perubahan',
          'platform': 'Web, Mobile & Backend',
          'deskripsi':
              'Menonaktifkan sementara (hold) fitur Rencana Kinerja (RK) pada menu, form, tabel, dan laporan; perhitungan nilai capaian mengacu pada rata-rata capaian kegiatan harian.'
        },
      ],
    },
    {
      'versi': 'v1.1.0',
      'judul': 'Peluncuran Aplikasi SI-CKP Mobile (Android) & Integrasi Cloud',
      'tanggal': '2026-11-12',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Mobile',
          'deskripsi':
              'Rilis aplikasi SI-CKP Mobile untuk Android (APK) dengan fitur Beranda, Input Kegiatan Harian, Upload Bukti Dukung, Riwayat Kegiatan, dan Monitoring Nilai CKP.'
        },
        {
          'kategori': 'Perbaikan',
          'platform': 'Backend',
          'deskripsi':
              'Migrasi database ke PostgreSQL (Supabase) dan penyimpanan bukti dukung ke Supabase Storage untuk sinkronisasi real-time antara Web dan Mobile.'
        },
      ],
    },
    {
      'versi': 'v1.0.0',
      'judul': 'Rilis Awal Sistem Informasi CKP Harian (SI-CKP)',
      'tanggal': '2026-11-02',
      'perubahan': [
        {
          'kategori': 'Fitur Baru',
          'platform': 'Web & Backend',
          'deskripsi':
              'Peluncuran perdana SI-CKP Harian meliputi pencatatan kegiatan harian pegawai, manajemen bukti dukung (file & link), kalender pengisian harian, penilaian perilaku kerja (BerAKHLAK), dan perhitungan nilai CKP bulanan.'
        },
      ],
    },
  ];

  List<dynamic> _changelogs = _fallbackChangelogs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getChangelogs();
      if (mounted && list.isNotEmpty) {
        setState(() => _changelogs = list);
      }
    } catch (_) {
      // Gunakan fallback jika offline
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog & Pembaruan Sistem'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _changelogs.length + 1,
          itemBuilder: (ctx, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Riwayat Pembaruan SI-CKP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _loading
                                ? 'Memuat pembaruan terbaru...'
                                : 'Daftar fitur baru, peningkatan, dan perubahan sistem untuk seluruh pengguna.',
                            style: const TextStyle(color: Color(0xFFBAE6FD), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final rel = _changelogs[index - 1] as Map<String, dynamic>;
            final isLatest = index == 1;
            final versi = rel['versi']?.toString() ?? '';
            final judul = rel['judul']?.toString() ?? '';
            final tanggal = rel['tanggal']?.toString() ?? '';
            final perubahan = (rel['perubahan'] as List?) ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLatest ? const Color(0xFF7DD3FC) : const Color(0xFFE2E8F0),
                  width: isLatest ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isLatest ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLatest ? const Color(0xFF0284C7) : const Color(0xFF334155),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    versi,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isLatest) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Terbaru',
                                      style: TextStyle(
                                        color: Color(0xFF065F46),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              tanggal,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          judul,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: perubahan.map((raw) {
                        final item = raw as Map<String, dynamic>;
                        final kat = item['kategori']?.toString() ?? 'Pembaruan';
                        final plat = item['platform']?.toString() ?? '';
                        final desc = item['deskripsi']?.toString() ?? '';

                        final isNew = kat.toLowerCase().contains('fitur');
                        final badgeBg = isNew ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE);
                        final badgeFg = isNew ? const Color(0xFF065F46) : const Color(0xFF1E40AF);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  kat,
                                  style: TextStyle(
                                    color: badgeFg,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (plat.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          plat,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    Text(
                                      desc,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF334155),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
