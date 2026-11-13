import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class WatermarkedPhotoResult {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String metadataText;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;

  WatermarkedPhotoResult({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.metadataText,
    required this.capturedAt,
    this.latitude,
    this.longitude,
  });
}

class PhotoWatermark {
  static String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final d = dt.day.toString().padLeft(2, '0');
    final m = months[dt.month - 1];
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$d $m $y, $hh:$mm:$ss';
  }

  static Future<Position?> _getCurrentPositionSafe() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  /// Mengambil koordinat GPS + timestamp saat ini dan menggambarnya langsung (burn watermark)
  /// pada bytes foto kamera.
  static Future<WatermarkedPhotoResult> stampCameraPhoto(Uint8List rawBytes) async {
    final now = DateTime.now();
    final timeStr = _formatDateTime(now);
    final pos = await _getCurrentPositionSafe();

    final String coordStr;
    if (pos != null) {
      final lat = pos.latitude.toStringAsFixed(6);
      final lng = pos.longitude.toStringAsFixed(6);
      final acc = pos.accuracy.round();
      coordStr = '$lat, $lng (±${acc}m)';
    } else {
      coordStr = 'GPS tidak aktif / izin lokasi ditolak';
    }

    final metadataText = '📍 Koordinat: $coordStr | 🕒 Waktu: $timeStr';

    try {
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: 1200,
      );
      final frame = await codec.getNextFrame();
      final ui.Image originalImage = frame.image;

      final double width = originalImage.width.toDouble();
      final double height = originalImage.height.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // 1. Gambar foto asli
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // 2. Siapkan teks watermark di bagian bawah foto
      final double fontSizeTitle = (width * 0.025).clamp(16.0, 28.0);
      final double fontSizeBody = (width * 0.022).clamp(14.0, 24.0);
      final double padding = (width * 0.025).clamp(16.0, 32.0);

      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: 'KASI JADI — Jurnal Aktivitas & Kinerja\n',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: const Color(0xFF38BDF8),
              fontSize: fontSizeTitle,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          TextSpan(
            text: 'Koordinat : $coordStr\n',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: Colors.white,
              fontSize: fontSizeBody,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          TextSpan(
            text: 'Waktu     : $timeStr',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: const Color(0xFFFDE047),
              fontSize: fontSizeBody,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - (padding * 2));

      final double boxHeight = textPainter.height + (padding * 1.4);
      final double boxTop = height - boxHeight;

      // 3. Gambar latar belakang semi-transparan di bawah foto
      final bgPaint = Paint()..color = const Color(0xB80F172A);
      canvas.drawRect(Rect.fromLTWH(0, boxTop, width, boxHeight), bgPaint);

      // Garis aksen biru di atas bar watermark
      final borderPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(0, boxTop), Offset(width, boxTop), borderPaint);

      // 4. Gambar teks di atas kotak
      textPainter.paint(canvas, Offset(padding, boxTop + (padding * 0.7)));

      final picture = recorder.endRecording();
      final ui.Image stampedImage = await picture.toImage(width.toInt(), height.toInt());
      final ByteData? pngData = await stampedImage.toByteData(format: ui.ImageByteFormat.png);

      if (pngData != null) {
        final stampedBytes = pngData.buffer.asUint8List();
        return WatermarkedPhotoResult(
          bytes: stampedBytes,
          fileName: 'foto_geotag_${now.millisecondsSinceEpoch}.png',
          mimeType: 'image/png',
          metadataText: metadataText,
          capturedAt: now,
          latitude: pos?.latitude,
          longitude: pos?.longitude,
        );
      }
    } catch (_) {
      // Fallback jika proses kanvas gagal: tetap simpan foto asli beserta metadata koordinat & waktu
    }

    return WatermarkedPhotoResult(
      bytes: rawBytes,
      fileName: 'foto_${now.millisecondsSinceEpoch}.jpg',
      mimeType: 'image/jpeg',
      metadataText: metadataText,
      capturedAt: now,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );
  }
}

