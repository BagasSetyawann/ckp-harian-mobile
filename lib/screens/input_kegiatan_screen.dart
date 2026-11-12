import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PendingFileItem {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  PendingFileItem({required this.name, required this.bytes, required this.mimeType});
}

class PendingLinkItem {
  String judul;
  String url;
  String platform;
  PendingLinkItem({this.judul = '', this.url = '', this.platform = 'Google Drive'});
}

class InputKegiatanScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Map<String, dynamic>? editActivity;

  const InputKegiatanScreen({super.key, this.onSuccess, this.editActivity});

  @override
  State<InputKegiatanScreen> createState() => _InputKegiatanScreenState();
}

class _InputKegiatanScreenState extends State<InputKegiatanScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _periods = [];
  List<dynamic> _plans = [];
  int? _selectedPeriodId;
  int? _selectedPlanId;
  String _tanggal = DateTime.now().toIso8601String().split('T')[0];
  String _statusKegiatan = 'selesai';

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _targetController = TextEditingController();
  final _satuanController = TextEditingController();
  final _realisasiController = TextEditingController();
  final _catatanController = TextEditingController();

  final List<PendingFileItem> _pendingFiles = [];
  final List<PendingLinkItem> _pendingLinks = [];

  bool _loadingInit = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _loadingInit = true);
    try {
      final periods = await ApiService.getPeriods();
      _periods = periods;

      if (widget.editActivity != null) {
        final act = widget.editActivity!;
        _selectedPeriodId = (act['period_id'] as num?)?.toInt();
        _selectedPlanId = (act['performance_plan_id'] as num?)?.toInt();
        _tanggal = (act['tanggal'] ?? _tanggal).toString();
        _statusKegiatan = (act['status_kegiatan'] ?? 'selesai').toString();
        _namaController.text = (act['nama_kegiatan'] ?? '').toString();
        _deskripsiController.text = (act['deskripsi'] ?? '').toString();
        _targetController.text = act['target']?.toString() ?? '';
        _satuanController.text = (act['satuan'] ?? '').toString();
        _realisasiController.text = act['realisasi']?.toString() ?? '';
        _catatanController.text = (act['catatan'] ?? '').toString();
      } else if (periods.isNotEmpty) {
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

      if (_selectedPeriodId != null) {
        _plans = await ApiService.getPerformancePlans(periodId: _selectedPeriodId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _onPeriodChanged(int? periodId) async {
    setState(() {
      _selectedPeriodId = periodId;
      _selectedPlanId = null;
    });
    if (periodId != null) {
      try {
        final plans = await ApiService.getPerformancePlans(periodId: periodId);
        if (mounted) setState(() => _plans = plans);
      } catch (_) {}
    }
  }

  void _onPlanChanged(int? planId) {
    setState(() {
      _selectedPlanId = planId;
      if (planId != null) {
        final plan = _plans.firstWhere((p) => p['id'] == planId, orElse: () => null);
        if (plan != null && (plan['satuan'] ?? '').toString().isNotEmpty) {
          _satuanController.text = plan['satuan'].toString();
        }
      }
    });
  }

  int get _calculatedCapaian {
    final t = double.tryParse(_targetController.text) ?? 0;
    final r = double.tryParse(_realisasiController.text) ?? 0;
    if (t <= 0) return 0;
    return ((r / t) * 100).round().clamp(0, 100);
  }

  String _guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickCameraPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 82);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      setState(() {
        _pendingFiles.add(PendingFileItem(
          name: photo.name.isNotEmpty ? photo.name : 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg',
          bytes: bytes,
          mimeType: _guessMimeType(photo.name),
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'],
      );
      if (result == null) return;
      setState(() {
        for (final f in result.files) {
          if (f.bytes != null) {
            _pendingFiles.add(PendingFileItem(
              name: f.name,
              bytes: f.bytes!,
              mimeType: _guessMimeType(f.name),
            ));
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
    }
  }

  void _showAddLinkDialog() {
    final judulCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String platform = 'Google Drive';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Link Bukti Dukung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: judulCtrl,
              decoration: const InputDecoration(labelText: 'Judul Dokumen / Link *', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL (https://...) *',
                hintText: 'https://drive.google.com/...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: platform,
              decoration: const InputDecoration(labelText: 'Platform', border: OutlineInputBorder(), isDense: true),
              items: ['Google Drive', 'OneDrive', 'SharePoint', 'Dropbox', 'Website Instansi', 'Lainnya']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => platform = v ?? 'Google Drive',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (judulCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
              setState(() {
                _pendingLinks.add(PendingLinkItem(
                  judul: judulCtrl.text.trim(),
                  url: urlCtrl.text.trim(),
                  platform: platform,
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPeriodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih periode terlebih dahulu')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final payload = <String, dynamic>{
        'period_id': _selectedPeriodId,
        'performance_plan_id': _selectedPlanId,
        'tanggal': _tanggal,
        'nama_kegiatan': _namaController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'target': double.tryParse(_targetController.text),
        'satuan': _satuanController.text.trim(),
        'realisasi': double.tryParse(_realisasiController.text),
        'status_kegiatan': _statusKegiatan,
        'catatan': _catatanController.text.trim(),
      };

      int activityId;
      if (widget.editActivity != null) {
        activityId = widget.editActivity!['id'] as int;
        await ApiService.updateActivity(activityId, payload);
      } else {
        final created = await ApiService.createActivity(payload);
        activityId = created['id'] as int;
      }

      // Upload bukti dukung (jika ada)
      for (final file in _pendingFiles) {
        await ApiService.uploadEvidenceFile(
          activityId: activityId,
          fileName: file.name,
          bytes: file.bytes,
          mimeType: file.mimeType,
        );
      }

      for (final link in _pendingLinks) {
        await ApiService.addEvidenceLink(
          activityId: activityId,
          judul: link.judul,
          url: link.url,
          platform: link.platform,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editActivity != null ? 'Kegiatan berhasil diperbarui!' : 'Kegiatan CKP harian berhasil disimpan!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      // Reset form jika input baru
      if (widget.editActivity == null) {
        _namaController.clear();
        _deskripsiController.clear();
        _targetController.clear();
        _realisasiController.clear();
        _catatanController.clear();
        setState(() {
          _pendingFiles.clear();
          _pendingLinks.clear();
        });
      }

      widget.onSuccess?.();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInit) {
      return const Center(child: CircularProgressIndicator());
    }

    final isEdit = widget.editActivity != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFF0284C7), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit
                        ? 'Perbarui data kegiatan harian Anda.'
                        : 'Isi kegiatan harian & lampirkan bukti dukung dalam satu langkah praktis.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF0369A1), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Periode & Tanggal
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedPeriodId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Periode *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: _periods.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'] as int,
                      child: Text(p['nama'].toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5)),
                    );
                  }).toList(),
                  onChanged: _onPeriodChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final initial = DateTime.tryParse(_tanggal) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _tanggal = picked.toIso8601String().split('T')[0]);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(_tanggal, style: const TextStyle(fontSize: 13.5)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rencana Kinerja (RK)
          DropdownButtonFormField<int?>(
            value: _selectedPlanId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Rencana Kinerja / RK (Opsional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('— Tanpa RK —', style: TextStyle(fontSize: 13.5))),
              ..._plans.map((p) {
                return DropdownMenuItem<int?>(
                  value: p['id'] as int,
                  child: Text(
                    '${p['kode'] ?? 'RK'} — ${p['nama']}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                );
              }),
            ],
            onChanged: _onPlanChanged,
          ),
          const SizedBox(height: 14),

          // Nama Kegiatan
          TextFormField(
            controller: _namaController,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kegiatan wajib diisi' : null,
            decoration: InputDecoration(
              labelText: 'Nama Kegiatan Harian *',
              hintText: 'Cth: Pemeriksaan data hasil survei lapangan',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Deskripsi
          TextFormField(
            controller: _deskripsiController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Deskripsi Singkat (Opsional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Target, Realisasi, Satuan, Capaian
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Target',
                    hintText: '10',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _realisasiController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Realisasi',
                    hintText: '10',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _satuanController,
                  decoration: InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'Dokumen',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real-time Capaian Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Persentase Capaian Otomatis:', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                Text(
                  '$_calculatedCapaian%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _calculatedCapaian >= 100 ? const Color(0xFF059669) : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Status Kegiatan Quick Chips
          const Text('Status Kegiatan:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'val': 'selesai', 'label': '✓ Selesai'},
              {'val': 'dalam_proses', 'label': '⏳ Dalam Proses'},
              {'val': 'ditunda', 'label': '⏸ Ditunda'},
            ].map((s) {
              final selected = _statusKegiatan == s['val'];
              return ChoiceChip(
                label: Text(s['label']!),
                selected: selected,
                onSelected: (_) => setState(() => _statusKegiatan = s['val']!),
                selectedColor: const Color(0xFFE0F2FE),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Catatan
          TextFormField(
            controller: _catatanController,
            decoration: InputDecoration(
              labelText: 'Catatan Tambahan (Opsional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          // Bukti Dukung Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📎 Lampirkan Bukti Dukung (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ambil foto dokumentasi langsung atau pilih dokumen/link.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickCameraPhoto,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Kamera', style: TextStyle(fontSize: 12.5)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Pilih File', style: TextStyle(fontSize: 12.5)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showAddLinkDialog,
                      icon: const Icon(Icons.add_link, size: 18),
                      label: const Text('Tambah Link', style: TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),

                if (_pendingFiles.isNotEmpty || _pendingLinks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                ],

                ..._pendingFiles.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final f = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF0284C7)),
                    title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                    subtitle: Text('${(f.bytes.length / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _pendingFiles.removeAt(idx)),
                    ),
                  );
                }),

                ..._pendingLinks.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final l = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link, color: Color(0xFF7C3AED)),
                    title: Text(l.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                    subtitle: Text(l.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _pendingLinks.removeAt(idx)),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _handleSubmit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _submitting
                    ? 'Menyimpan...'
                    : (isEdit ? 'Simpan Perubahan' : 'Simpan Kegiatan CKP'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

