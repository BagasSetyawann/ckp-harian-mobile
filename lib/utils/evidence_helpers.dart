import 'dart:io' show File;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'photo_watermark.dart';

class PickedEvidenceFile {
  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final String? keterangan;

  const PickedEvidenceFile({
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    this.keterangan,
  });
}

class PendingLinkInput {
  final String judul;
  final String url;
  final String? platform;

  const PendingLinkInput({
    required this.judul,
    required this.url,
    this.platform,
  });
}

class EvidenceHelpers {
  static String inferMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'application/octet-stream';
  }

  static Future<WatermarkedPhotoResult?> captureGeotaggedPhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (photo == null) return null;
    final rawBytes = await photo.readAsBytes();
    return PhotoWatermark.stampCameraPhoto(rawBytes);
  }

  static Future<List<PickedEvidenceFile>> pickEvidenceFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'],
    );
    if (result == null) return [];

    final files = <PickedEvidenceFile>[];
    for (final pf in result.files) {
      Uint8List? bytes = pf.bytes;
      if (bytes == null && pf.path != null) {
        bytes = await File(pf.path!).readAsBytes();
      }
      if (bytes != null) {
        files.add(
          PickedEvidenceFile(
            fileName: pf.name,
            bytes: bytes,
            mimeType: inferMimeType(pf.name),
          ),
        );
      }
    }
    return files;
  }

  static Future<PendingLinkInput?> showAddLinkDialog(BuildContext context) async {
    final judulCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final platformCtrl = TextEditingController(text: 'Google Drive');

    final res = await showDialog<PendingLinkInput>(
      context: context,
      builder: (ctx) {
        final p = AppTheme.of(ctx);
        return AlertDialog(
          title: const Text('Tambah Tautan Bukti Dukung', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tautan',
                    hintText: 'Contoh: Laporan Publikasi Triwulan',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  keyboardType: TextInputType.url,
                  style: AppTheme.mono(size: 12.5, color: p.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'URL / Link',
                    hintText: 'https://drive.google.com/...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: platformCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Platform (Opsional)',
                    hintText: 'Google Drive, Notion, Web, dll',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final j = judulCtrl.text.trim();
                final u = urlCtrl.text.trim();
                if (j.isEmpty || u.isEmpty) return;
                Navigator.pop(
                  ctx,
                  PendingLinkInput(
                    judul: j,
                    url: u,
                    platform: platformCtrl.text.trim().isEmpty ? null : platformCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('BERES! Tambahkan'),
            ),
          ],
        );
      },
    );
    return res;
  }
}

