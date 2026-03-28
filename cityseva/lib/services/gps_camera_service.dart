import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// GPS Camera Service
/// Takes a photo and stamps GPS coordinates, address and timestamp on it
/// Like a real GPS camera used in government field work
class GpsCameraService {

  /// Take a photo from camera and stamp GPS + time on it
  static Future<GpsPhotoResult> takeGeoTaggedPhoto() async {
    try {
      // Step 1: Pick image from camera
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (picked == null) return GpsPhotoResult(cancelled: true);

      // Step 2: Get current GPS location
      Position? position;
      String address = 'Location unavailable';
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 8));

        // Try to get address
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: 5));
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final parts = [p.subLocality, p.locality, p.administrativeArea]
                .where((s) => s != null && s!.isNotEmpty)
                .toList();
            address = parts.join(', ');
          }
        } catch (_) {
          address = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        }
      } catch (_) {
        // GPS failed — still stamp time
      }

      // Step 3: Stamp GPS info on the image
      final stampedFile = await _stampImageWithGps(
        File(picked.path),
        position: position,
        address: address,
      );

      return GpsPhotoResult(
        file: stampedFile,
        position: position,
        address: address,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return GpsPhotoResult(error: e.toString());
    }
  }

  /// Stamp GPS coordinates, address and timestamp on the image
  static Future<File> _stampImageWithGps(
    File imageFile, {
    Position? position,
    required String address,
  }) async {
    // Load original image bytes
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;

    final width = originalImage.width.toDouble();
    final height = originalImage.height.toDouble();

    // Create canvas to draw on image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Draw original image
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // Stamp bar height
    final barHeight = height * 0.12;
    final barTop = height - barHeight;

    // Draw semi-transparent black bar at bottom
    canvas.drawRect(
      Rect.fromLTWH(0, barTop, width, barHeight),
      Paint()..color = const Color(0xCC000000),
    );

    // Draw CitySeva branding bar at top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, barHeight * 0.5),
      Paint()..color = const Color(0xCC1565C0),
    );

    // Text style helper
    ui.ParagraphBuilder _makeText(String text, double fontSize, Color color, {bool bold = false}) {
      final style = ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      );
      final builder = ui.ParagraphBuilder(style)
        ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal))
        ..addText(text);
      return builder;
    }

    final fontSize = width * 0.035;
    final padding = width * 0.025;
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    // Top bar — CitySeva label
    final titleBuilder = _makeText('CitySeva — Verified Photo', fontSize * 0.9, Colors.white, bold: true);
    final titlePara = titleBuilder.build()..layout(ui.ParagraphConstraints(width: width - padding * 2));
    canvas.drawParagraph(titlePara, Offset(padding, barHeight * 0.08));

    // Bottom bar content
    double textY = barTop + padding * 0.6;

    // Date & Time
    final dtBuilder = _makeText('$dateStr  $timeStr', fontSize, Colors.white, bold: true);
    final dtPara = dtBuilder.build()..layout(ui.ParagraphConstraints(width: width - padding * 2));
    canvas.drawParagraph(dtPara, Offset(padding, textY));
    textY += fontSize * 1.5;

    // GPS Coordinates
    if (position != null) {
      final gpsText = 'GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      final gpsBuilder = _makeText(gpsText, fontSize * 0.85, const Color(0xFF90CAF9));
      final gpsPara = gpsBuilder.build()..layout(ui.ParagraphConstraints(width: width - padding * 2));
      canvas.drawParagraph(gpsPara, Offset(padding, textY));
      textY += fontSize * 1.4;
    }

    // Address
    if (address.isNotEmpty && address != 'Location unavailable') {
      final addrBuilder = _makeText(address, fontSize * 0.8, const Color(0xFFB0BEC5));
      final addrPara = addrBuilder.build()..layout(ui.ParagraphConstraints(width: width - padding * 2));
      canvas.drawParagraph(addrPara, Offset(padding, textY));
    }

    // Accuracy indicator dot
    if (position != null) {
      canvas.drawCircle(
        Offset(width - padding * 2, barTop + barHeight * 0.5),
        width * 0.015,
        Paint()..color = const Color(0xFF4CAF50),
      );
      final accBuilder = _makeText('GPS', fontSize * 0.7, const Color(0xFF4CAF50), bold: true);
      final accPara = accBuilder.build()..layout(ui.ParagraphConstraints(width: width * 0.15));
      canvas.drawParagraph(accPara, Offset(width - padding * 4.5, barTop + barHeight * 0.35));
    }

    // Convert to image
    final picture = recorder.endRecording();
    final stampedImage = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await stampedImage.toByteData(format: ui.ImageByteFormat.png);
    final stampedBytes = byteData!.buffer.asUint8List();

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'cityseva_gps_${now.millisecondsSinceEpoch}.png';
    final outputFile = File('${tempDir.path}/$fileName');
    await outputFile.writeAsBytes(stampedBytes);

    return outputFile;
  }
}

class GpsPhotoResult {
  final File? file;
  final Position? position;
  final String? address;
  final DateTime? timestamp;
  final bool cancelled;
  final String? error;

  GpsPhotoResult({
    this.file,
    this.position,
    this.address,
    this.timestamp,
    this.cancelled = false,
    this.error,
  });

  bool get success => file != null && error == null && !cancelled;
}
