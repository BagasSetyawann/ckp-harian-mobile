import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/evidence_helpers.dart';
import '../widgets/ui_components.dart';

class InputKegiatanScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Map<String, dynamic>? editActivity;

  const InputKegiatanScreen({
    super.key,
    this.onSuccess,
    this.editActivity,
  });

  @override
  State<InputKegiatanScreen> createState() => _InputKegiatanScreenState();
}

class _InputKegiatanScreenState extends State<InputKegiatanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _satuanCtrl = TextEditingController();
  final _realisasiCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  List<dynamic> _periods = [];
  int? _periodId;
  late DateTime _tanggal;
  String _status = 'selesai';

  bool _loadingMeta = true;
  bool _submitting = false;
  bool _capturingGps = false;

  final List<PickedEvidenceFile> _pendingFiles = [];
  final List<PendingLinkInput> _pendingLinks = [];

  bool get _isEditing => widget.editActivity != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editActivity;
    if (edit != null) {
      _namaCtrl.text = (edit['nama_kegiatan'] ?? '').toString();
      _deskripsiCtrl.text = (edit['deskripsi'] ?? '').toString();
      _targetCtrl.text = edit['target'] != null ? edit['target'].toString() : '';
      _satuanCtrl.text = (edit['satuan'] ?? '').toString();
      _realisasiCtrl.text = edit['realisasi'] != null ? edit['realisasi'].toString() : '';
      _catatanCtrl.text = (edit['catatan'] ?? '').toString();
      _status = (edit['status_kegiatan'] ?? 'selesai').toString();
      _periodId = edit['period_id'] as int?;
      _tanggal = DateTime.tryParse((edit['tanggal'] ?? '').toString()) ?? DateTime.now();
    } else {
      _tanggal = DateTime.now();
    }
    _targetCtrl.addListener(_onMetricChanged);
    _realisasiCtrl.addListener(_onMetricChanged);
    _loadPeriods();
  }

  void _onMetricChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _targetCtrl.dispose();
    _satuanCtrl.dispose();
    _realisasiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPeriods() async {
    try {
      final list = await ApiService.getPeriods();
      if (!mounted) return;
      int? defaultId = _periodId;
      if (defaultId == null && list.isNotEmpty) {
        final active = list.cast<Map<String, dynamic>>().firstWhere(
              (p) => p['is_active'] == 1 || p['status'] == 'aktif',
              orElse: () => Map<String, dynamic>.from(list.first as Map),
            );
        defaultId = active['id'] as int?;
      }
      setState(() {
        _periods = list;
        _periodId = defaultId;
        _loadingMeta = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  int get _computedPercentage {
    final t = double.tryParse(_targetCtrl.text.replaceAll(',', '.')) ?? 0;
    final r = double.tryParse(_realisasiCtrl.text.replaceAll(',', '.')) ?? 0;
    if (t <= 0) return _status == 'selesai' ? 100 : 0;
    return ((r / t) * 100).round().clamp(0, 100);
  }

  String get _formattedDate {
    final y = _tanggal.year.toString().padLeft(4, '0');
    final m = _tanggal.month.toString().padLeft(2, '0');
    final d = _tanggal.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _tanggal = picked);
    }
  }

  Future<void> _captureCameraGps() async {
    setState(() => _capturingGps = true);
    try {
      final res = await EvidenceHelpers.captureGeotaggedPhoto();
      if (res != null && mounted) {
        setState(() {
          _pendingFiles.add(
            PickedEvidenceFile(
              fileName: res.fileName,
              bytes: res.bytes,
              mimeType: res.mimeType,
              keterangan: res.metadataText,
            ),
          );
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil foto kamera atau koordinat GPS.')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturingGps = false);
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final files = await EvidenceHelpers.pickEvidenceFiles();
      if (files.isNotEmpty && mounted) {
        setState(() => _pendingFiles.addAll(files));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih berkas.')),
        );
      }
    }
  }

  Future<void> _addLink() async {
    final link = await EvidenceHelpers.showAddLinkDialog(context);
    if (link != null && mounted) {
      setState(() => _pendingLinks.add(link));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_periodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periode kinerja belum tersedia.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final t = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
      final r = double.tryParse(_realisasiCtrl.text.replaceAll(',', '.'));

      final payload = <String, dynamic>{
        'period_id': _periodId,
        'tanggal': _formattedDate,
        'nama_kegiatan': _namaCtrl.text.trim(),
        'deskripsi': _deskripsiCtrl.text.trim().isEmpty ? null : _deskripsiCtrl.text.trim(),
        'target': t,
        'satuan': _satuanCtrl.text.trim().isEmpty ? null : _satuanCtrl.text.trim(),
        'realisasi': r,
        'status_kegiatan': _status,
        'catatan': _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
      };

      int activityId;
      if (_isEditing) {
        activityId = widget.editActivity!['id'] as int;
        await ApiService.updateActivity(activityId, payload);
      } else {
        final created = await ApiService.createActivity(payload);
        activityId = created['id'] as int;
      }

      for (final f in _pendingFiles) {
        await ApiService.uploadEvidenceFile(
          activityId: activityId,
          fileName: f.fileName,
          bytes: f.bytes,
          mimeType: f.mimeType,
          keterangan: f.keterangan,
        );
      }
      for (final l in _pendingLinks) {
        await ApiService.addEvidenceLink(
          activityId: activityId,
          judul: l.judul,
          url: l.url,
          platform: l.platform,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Kegiatan berhasil diperbarui.' : 'Kegiatan harian berhasil dicatat.'),
        ),
      );

      if (!_isEditing) {
        _namaCtrl.clear();
        _deskripsiCtrl.clear();
        _targetCtrl.clear();
        _satuanCtrl.clear();
        _realisasiCtrl.clear();
        _catatanCtrl.clear();
        setState(() {
          _pendingFiles.clear();
          _pendingLinks.clear();
          _status = 'selesai';
        });
      }

      widget.onSuccess?.call();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan kegiatan: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildBody(BuildContext context) {
    final p = AppTheme.of(context);
    final pct = _computedPercentage;

    if (_loadingMeta) {
      return Center(child: CircularProgressIndicator(color: p.primary));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Section 1: Periode & Tanggal
          HairlineCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode & Waktu',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(_periodId),
                  initialValue: _periodId,
                  decoration: const InputDecoration(labelText: 'Periode'),
                  dropdownColor: p.surface,
                  items: _periods.map((item) {
                    final map = item as Map<String, dynamic>;
                    final label = (map['nama'] ?? 'Periode').toString();
                    final active = map['is_active'] == 1 || map['status'] == 'aktif';
                    return DropdownMenuItem<int>(
                      value: map['id'] as int,
                      child: Text('$label${active ? ' • Aktif' : ''}'),
                    );
                  }).toList(),
                  onChanged: _isEditing ? null : (v) => setState(() => _periodId = v),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _isEditing ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kegiatan',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      _formattedDate,
                      style: AppTheme.mono(size: 13.5, color: p.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Section 2: Detail Kegiatan & Capaian
          HairlineCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Aktivitas',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kegiatan *',
                    hintText: 'Contoh: Rekapitulasi data statistik bulanan',
                  ),
                  maxLines: 2,
                  minLines: 1,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kegiatan wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deskripsiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Uraian Singkat (Opsional)',
                    hintText: 'Jelaskan output atau detail pelaksanaan...',
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTheme.mono(size: 13.5, color: p.textPrimary),
                        decoration: const InputDecoration(labelText: 'Target', hintText: '10'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _realisasiCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTheme.mono(size: 13.5, color: p.textPrimary),
                        decoration: const InputDecoration(labelText: 'Realisasi', hintText: '10'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _satuanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Satuan Output',
                    hintText: 'Dokumen, Laporan, Tabel, Kunjungan',
                  ),
                ),
                const SizedBox(height: 14),

                // Progress preview bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Capaian Terhitung',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                          ),
                          const Spacer(),
                          MonoPill(
                            text: '$pct%',
                            color: pct >= 80 ? p.success : p.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          minHeight: 6,
                          backgroundColor: p.border,
                          color: pct >= 80 ? p.success : p.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Status Pelaksanaan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Selesai'),
                      selected: _status == 'selesai',
                      onSelected: (_) => setState(() => _status = 'selesai'),
                      selectedColor: p.successBg,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _status == 'selesai' ? p.success : p.textSecondary,
                      ),
                      side: BorderSide(color: _status == 'selesai' ? p.success : p.border),
                    ),
                    ChoiceChip(
                      label: const Text('Dalam Proses'),
                      selected: _status == 'proses',
                      onSelected: (_) => setState(() => _status = 'proses'),
                      selectedColor: p.warningBg,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _status == 'proses' ? p.warning : p.textSecondary,
                      ),
                      side: BorderSide(color: _status == 'proses' ? p.warning : p.border),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _catatanCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    hintText: 'Kendala atau keterangan tambahan',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Section 3: Bukti Dukung (Kamera Geotag, File, Link)
          HairlineCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lampiran Bukti Dukung',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto kamera otomatis merekam koordinat GPS & timestamp watermark.',
                  style: TextStyle(fontSize: 12, color: p.textMuted),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _capturingGps ? null : _captureCameraGps,
                        icon: _capturingGps
                            ? SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
                              )
                            : Icon(Icons.camera_alt_outlined, size: 17, color: p.primary),
                        label: Text(_capturingGps ? 'Lokasi...' : 'Kamera GPS'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDocuments,
                        icon: Icon(Icons.upload_file_outlined, size: 17, color: p.textSecondary),
                        label: const Text('Pilih File'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addLink,
                    icon: Icon(Icons.link_rounded, size: 17, color: p.info),
                    label: const Text('Tambah Tautan URL'),
                  ),
                ),

                if (_pendingFiles.isNotEmpty || _pendingLinks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: p.border),
                  const SizedBox(height: 10),
                  ..._pendingFiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final f = entry.value;
                    final hasGps = f.keterangan != null && f.keterangan!.isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasGps ? Icons.location_on_outlined : Icons.insert_drive_file_outlined,
                            size: 18,
                            color: hasGps ? p.info : p.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textPrimary),
                                ),
                                if (hasGps)
                                  Text(
                                    f.keterangan!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.mono(size: 10.5, color: p.info),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 17, color: p.textMuted),
                            onPressed: () => setState(() => _pendingFiles.removeAt(idx)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  }),
                  ..._pendingLinks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final l = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: p.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, size: 18, color: p.info),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.judul,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textPrimary),
                                ),
                                Text(
                                  l.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.mono(size: 10.5, color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 17, color: p.textMuted),
                            onPressed: () => setState(() => _pendingLinks.removeAt(idx)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: p.onPrimary),
                  )
                : Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Kegiatan Harian'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Kegiatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        body: _buildBody(context),
      );
    }
    return _buildBody(context);
  }
}
