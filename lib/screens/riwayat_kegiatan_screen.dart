import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/evidence_helpers.dart';
import '../widgets/ui_components.dart';
import 'input_kegiatan_screen.dart';

class RiwayatKegiatanScreen extends StatefulWidget {
  const RiwayatKegiatanScreen({super.key});

  @override
  State<RiwayatKegiatanScreen> createState() => _RiwayatKegiatanScreenState();
}

class _RiwayatKegiatanScreenState extends State<RiwayatKegiatanScreen> {
  List<dynamic> _periods = [];
  int? _selectedPeriodId;
  List<dynamic> _activities = [];
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
      await _loadActivities();
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
          _error = 'Gagal memuat riwayat kegiatan.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getActivities(periodId: _selectedPeriodId);
      if (mounted) setState(() => _activities = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengambil daftar kegiatan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteActivity(Map<String, dynamic> act) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kegiatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Hapus "${act['nama_kegiatan']}"? Seluruh bukti dukung terkait juga akan terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.of(ctx).danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    try {
      await ApiService.deleteActivity(act['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kegiatan berhasil dihapus.')),
        );
      }
      await _loadActivities();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openEvidenceSheet(Map<String, dynamic> act) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EvidenceSheet(
        activity: act,
        onChanged: _loadActivities,
      ),
    );
  }

  Future<void> _downloadExcel() async {
    if (_selectedPeriodId == null) return;
    final uri = Uri.parse(ApiService.getExcelExportUrl(periodId: _selectedPeriodId!));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan Excel.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);

    return Column(
      children: [
        if (_periods.isNotEmpty)
          PeriodSelectorBar(
            periods: _periods,
            selectedPeriodId: _selectedPeriodId,
            onChanged: (v) {
              setState(() => _selectedPeriodId = v);
              _loadActivities();
            },
            trailing: OutlinedButton.icon(
              onPressed: _selectedPeriodId == null ? null : _downloadExcel,
              icon: Icon(Icons.download_rounded, size: 15, color: p.success),
              label: Text('Excel', style: TextStyle(fontSize: 12, color: p.textPrimary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadActivities,
            color: p.primary,
            child: _loading
                ? Center(child: CircularProgressIndicator(color: p.primary))
                : _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          ExecutiveEmptyState(
                            icon: Icons.cloud_off_rounded,
                            title: 'Gagal Memuat Riwayat',
                            subtitle: _error!,
                            buttonLabel: 'Muat Ulang',
                            onPressed: _loadActivities,
                          ),
                        ],
                      )
                    : _activities.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: const [
                              ExecutiveEmptyState(
                                icon: Icons.inbox_outlined,
                                title: 'Belum Ada Kegiatan',
                                subtitle: 'Belum ada kegiatan harian tercatat pada periode yang dipilih.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            itemCount: _activities.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, idx) {
                              final act = _activities[idx] as Map<String, dynamic>;
                              final pct = (act['persentase_capaian'] as num?)?.toInt() ?? 0;
                              final isDone = act['status_kegiatan'] == 'selesai';
                              final fileCount = (act['jumlah_bukti'] as num?)?.toInt() ?? 0;
                              final linkCount = (act['jumlah_link'] as num?)?.toInt() ?? 0;
                              final totalBukti = fileCount + linkCount;
                              final gpsMeta = (act['bukti_keterangan'] ?? '').toString();

                              return HairlineCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        MonoPill(text: (act['tanggal'] ?? '-').toString()),
                                        const SizedBox(width: 8),
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
                                    const SizedBox(height: 10),
                                    Text(
                                      (act['nama_kegiatan'] ?? '-').toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: p.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (act['deskripsi'] != null && act['deskripsi'].toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        act['deskripsi'].toString(),
                                        style: TextStyle(fontSize: 12.5, color: p.textMuted, height: 1.4),
                                      ),
                                    ],
                                    if (act['target'] != null && act['realisasi'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Realisasi: ${act['realisasi']} / ${act['target']} ${act['satuan'] ?? ''}',
                                        style: AppTheme.mono(size: 11.5, color: p.textSecondary),
                                      ),
                                    ],
                                    if (gpsMeta.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: p.infoBg,
                                          borderRadius: BorderRadius.circular(9),
                                          border: Border.all(color: p.border, width: 1.4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on_rounded, size: 14, color: p.info),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                gpsMeta,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.mono(size: 10.5, weight: FontWeight.w600, color: p.info),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: p.border),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _openEvidenceSheet(act),
                                          borderRadius: BorderRadius.circular(9),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: p.tealBg,
                                              borderRadius: BorderRadius.circular(9),
                                              border: Border.all(color: p.border, width: 1.5),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.attach_file_rounded, size: 15, color: p.success),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '$totalBukti Bukti',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: p.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => InputKegiatanScreen(
                                                  editActivity: act,
                                                  onSuccess: () {
                                                    Navigator.of(context).pop();
                                                    _loadActivities();
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(9),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: p.surface,
                                              borderRadius: BorderRadius.circular(9),
                                              border: Border.all(color: p.border, width: 1.5),
                                            ),
                                            child: Icon(Icons.edit_rounded, size: 16, color: p.textPrimary),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _deleteActivity(act),
                                          borderRadius: BorderRadius.circular(9),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: p.danger,
                                              borderRadius: BorderRadius.circular(9),
                                              border: Border.all(color: p.border, width: 1.5),
                                            ),
                                            child: const Icon(Icons.delete_rounded, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}

class _EvidenceSheet extends StatefulWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onChanged;

  const _EvidenceSheet({required this.activity, required this.onChanged});

  @override
  State<_EvidenceSheet> createState() => _EvidenceSheetState();
}

class _EvidenceSheetState extends State<_EvidenceSheet> {
  List<dynamic> _files = [];
  List<dynamic> _links = [];
  bool _loading = true;
  bool _uploading = false;

  int get _activityId => widget.activity['id'] as int;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getEvidence(_activityId);
      if (mounted) {
        setState(() {
          _files = (data['files'] as List<dynamic>?) ?? [];
          _links = (data['links'] as List<dynamic>?) ?? [];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar bukti dukung.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadCameraGps() async {
    setState(() => _uploading = true);
    try {
      final res = await EvidenceHelpers.captureGeotaggedPhoto();
      if (res != null) {
        await ApiService.uploadEvidenceFile(
          activityId: _activityId,
          fileName: res.fileName,
          bytes: res.bytes,
          mimeType: res.mimeType,
          keterangan: res.metadataText,
        );
        widget.onChanged();
        await _loadEvidence();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unggah foto GPS: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _uploadFiles() async {
    setState(() => _uploading = true);
    try {
      final picked = await EvidenceHelpers.pickEvidenceFiles();
      for (final f in picked) {
        await ApiService.uploadEvidenceFile(
          activityId: _activityId,
          fileName: f.fileName,
          bytes: f.bytes,
          mimeType: f.mimeType,
          keterangan: f.keterangan,
        );
      }
      if (picked.isNotEmpty) {
        widget.onChanged();
        await _loadEvidence();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal unggah berkas: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addLink() async {
    final link = await EvidenceHelpers.showAddLinkDialog(context);
    if (link == null) return;
    setState(() => _uploading = true);
    try {
      await ApiService.addEvidenceLink(
        activityId: _activityId,
        judul: link.judul,
        url: link.url,
        platform: link.platform,
      );
      widget.onChanged();
      await _loadEvidence();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambah tautan: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openExternalUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: p.borderStrong, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti Dukung',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (widget.activity['nama_kegiatan'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),

            // Upload toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: KjNeoButton(
                      label: 'Kamera',
                      icon: Icons.camera_alt_rounded,
                      variant: KjButtonVariant.orange,
                      pill: false,
                      expand: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      onPressed: _uploading ? null : _uploadCameraGps,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KjNeoButton(
                      label: 'File',
                      icon: Icons.upload_file_rounded,
                      variant: KjButtonVariant.teal,
                      pill: false,
                      expand: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      onPressed: _uploading ? null : _uploadFiles,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KjNeoButton(
                      label: 'Tautan',
                      icon: Icons.link_rounded,
                      variant: KjButtonVariant.secondary,
                      pill: false,
                      expand: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      onPressed: _uploading ? null : _addLink,
                    ),
                  ),
                ],
              ),
            ),
            if (_uploading) LinearProgressIndicator(minHeight: 2, color: p.primary),

            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: p.primary))
                  : (_files.isEmpty && _links.isEmpty)
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: ExecutiveEmptyState(
                            icon: Icons.folder_open_outlined,
                            title: 'Belum Ada Bukti Dukung',
                            subtitle: 'Ambil foto kamera GPS, unggah dokumen, atau lampirkan tautan di atas.',
                          ),
                        )
                      : ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            ..._files.map((item) {
                              final f = item as Map<String, dynamic>;
                              final url = (f['path_file'] ?? f['url'] ?? '').toString();
                              final ket = (f['keterangan'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: HairlineCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  onTap: () => _openExternalUrl(url),
                                  child: Row(
                                    children: [
                                      Icon(
                                        f['jenis'] == 'foto' ? Icons.image_outlined : Icons.description_outlined,
                                        size: 20,
                                        color: p.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (f['nama_file'] ?? 'Berkas').toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: p.textPrimary,
                                              ),
                                            ),
                                            if (ket.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                ket,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.mono(size: 10.5, color: p.info),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: p.danger),
                                        onPressed: () async {
                                          await ApiService.deleteEvidenceFile(f['id'] as int);
                                          widget.onChanged();
                                          await _loadEvidence();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            ..._links.map((item) {
                              final l = item as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: HairlineCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  onTap: () => _openExternalUrl((l['url'] ?? '').toString()),
                                  child: Row(
                                    children: [
                                      Icon(Icons.link_rounded, size: 20, color: p.info),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (l['judul'] ?? 'Tautan').toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: p.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              (l['url'] ?? '').toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTheme.mono(size: 10.5, color: p.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: p.danger),
                                        onPressed: () async {
                                          await ApiService.deleteEvidenceLink(l['id'] as int);
                                          widget.onChanged();
                                          await _loadEvidence();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }
}
