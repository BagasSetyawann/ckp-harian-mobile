import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/photo_watermark.dart';
import 'input_kegiatan_screen.dart';

class RiwayatKegiatanScreen extends StatefulWidget {
  const RiwayatKegiatanScreen({super.key});

  @override
  State<RiwayatKegiatanScreen> createState() => _RiwayatKegiatanScreenState();
}

class _RiwayatKegiatanScreenState extends State<RiwayatKegiatanScreen> {
  List<dynamic> _periods = [];
  List<dynamic> _activities = [];
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
      await _fetchActivities();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchActivities() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getActivities(periodId: _selectedPeriodId);
      if (mounted) setState(() => _activities = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteActivity(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kegiatan?'),
        content: const Text('Kegiatan dan bukti dukung terkait akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteActivity(id);
      await _fetchActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kegiatan dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  void _openEditModal(Map<String, dynamic> act) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Edit Kegiatan Harian')),
          body: InputKegiatanScreen(
            editActivity: act,
            onSuccess: () {
              Navigator.pop(ctx);
              _fetchActivities();
            },
          ),
        ),
      ),
    );
  }

  void _openEvidenceBottomSheet(Map<String, dynamic> act) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _EvidenceSheet(
        activity: act,
        onChanged: _fetchActivities,
      ),
    );
  }

  void _downloadPeriodExcel() {
    if (_selectedPeriodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih periode terlebih dahulu')),
      );
      return;
    }
    final url = ApiService.getExcelExportUrl(periodId: _selectedPeriodId!);
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter & Download Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedPeriodId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Periode',
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
                    _fetchActivities();
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _downloadPeriodExcel,
                icon: const Icon(Icons.download_rounded, size: 17, color: Color(0xFF059669)),
                label: const Text('Excel', style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF059669)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              IconButton(
                onPressed: _fetchActivities,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _activities.isEmpty
                  ? const Center(
                      child: Text('Belum ada kegiatan pada periode ini.', style: TextStyle(color: Colors.grey)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchActivities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _activities.length,
                        itemBuilder: (ctx, i) {
                          final act = _activities[i] as Map<String, dynamic>;
                          final statusKeg = act['status_kegiatan']?.toString() ?? 'selesai';
                          final isSelesai = statusKeg == 'selesai';
                          final jumlahBukti = (act['jumlah_bukti'] ?? 0) + (act['jumlah_link'] ?? 0);
                          final capaian = act['persentase_capaian'] ?? 0;
                          final buktiKet = act['bukti_keterangan']?.toString();

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
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        act['tanggal']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSelesai ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSelesai ? '✓ Selesai' : statusKeg,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelesai ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  act['nama_kegiatan']?.toString() ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B)),
                                ),
                                if (act['deskripsi'] != null && act['deskripsi'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    act['deskripsi'].toString(),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                                if (buktiKet != null && buktiKet.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Text(
                                      buktiKet,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Realisasi: ${act['realisasi'] ?? '-'} / ${act['target'] ?? '-'} ${act['satuan'] ?? ''}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    Text(
                                      'Capaian: $capaian%',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _openEvidenceBottomSheet(act),
                                      icon: const Icon(Icons.attach_file, size: 16),
                                      label: Text('Bukti Dukung ($jumlahBukti)', style: const TextStyle(fontSize: 12.5)),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _openEditModal(act),
                                          icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFF475569)),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteActivity(act['id'] as int),
                                          icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red),
                                          tooltip: 'Hapus',
                                        ),
                                      ],
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getEvidence(widget.activity['id'] as int);
      if (mounted) {
        setState(() {
          _files = (res['files'] as List?) ?? [];
          _links = (res['links'] as List?) ?? [];
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadCameraWithGeotag() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return;

      setState(() => _uploading = true);
      final rawBytes = await photo.readAsBytes();
      final watermarked = await PhotoWatermark.stampCameraPhoto(rawBytes);

      await ApiService.uploadEvidenceFile(
        activityId: widget.activity['id'] as int,
        fileName: watermarked.fileName,
        bytes: watermarked.bytes,
        mimeType: watermarked.mimeType,
        keterangan: watermarked.metadataText,
      );
      await _load();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _uploadNewFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'],
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final f = result.files.first;
    final ext = f.name.split('.').last.toLowerCase();
    final mime = ext == 'pdf'
        ? 'application/pdf'
        : (ext == 'png' ? 'image/png' : (ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'application/octet-stream'));

    setState(() => _uploading = true);
    try {
      await ApiService.uploadEvidenceFile(
        activityId: widget.activity['id'] as int,
        fileName: f.name,
        bytes: f.bytes!,
        mimeType: mime,
      );
      await _load();
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bukti Dukung: ${widget.activity['nama_kegiatan']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _uploading ? null : _uploadCameraWithGeotag,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(_uploading ? 'Memproses...' : 'Kamera (GPS + Timestamp)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _uploadNewFile,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Pilih File'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else if (_files.isEmpty && _links.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Belum ada bukti dukung.', style: TextStyle(color: Colors.grey))),
            )
          else ...[
            ..._files.map((f) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file, color: Color(0xFF0284C7)),
                  title: Text(f['nama_file']?.toString() ?? ''),
                  subtitle: f['keterangan'] != null && f['keterangan'].toString().isNotEmpty
                      ? Text(
                          f['keterangan'].toString(),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () {
                          final url = f['path_file']?.toString();
                          if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () async {
                          await ApiService.deleteEvidenceFile(f['id'] as int);
                          await _load();
                          widget.onChanged();
                        },
                      ),
                    ],
                  ),
                )),
            ..._links.map((l) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: Color(0xFF7C3AED)),
                  title: Text(l['judul']?.toString() ?? ''),
                  subtitle: Text(l['url']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    onPressed: () async {
                      await ApiService.deleteEvidenceLink(l['id'] as int);
                      await _load();
                      widget.onChanged();
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
