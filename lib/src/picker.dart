import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'prepare_jpeg.dart';
import 'prepare_sheet.dart';
import 'prepare_theme.dart';

/// Camera or gallery. Capture then manual corner crop (no live auto-detect).
enum PreparedImageSource { camera, gallery }

/// JPEG result after crop + prepare. [extension] is always `jpg`.
class PreparedImage {
  const PreparedImage({
    required this.bytes,
    this.extension = 'jpg',
    required this.width,
    required this.height,
  });

  factory PreparedImage.fromJpeg(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    return PreparedImage(
      bytes: bytes,
      width: decoded?.width ?? 0,
      height: decoded?.height ?? 0,
    );
  }

  final Uint8List bytes;
  final String extension;
  final int width;
  final int height;

  int get sizeInBytes => bytes.length;
  String get fileName => 'image.$extension';
}

/// Pick → crop → rotate/resize/compress sheet → JPEG.
class ApprocImagePicker {
  const ApprocImagePicker({
    this.maxDimension = kDefaultMaxDimension,
    this.jpegQuality = kDefaultJpegQuality,
    this.theme = const ImagePrepareTheme(),
  });

  final int maxDimension;
  final int jpegQuality;
  final ImagePrepareTheme theme;

  /// Opens camera or gallery with crop, then the prepare sheet.
  ///
  /// Returns null if the user cancels. Call [onScanned] after crop (before the
  /// sheet) so the host can hide a loading overlay.
  Future<PreparedImage?> pick(
    BuildContext context, {
    required PreparedImageSource source,
    VoidCallback? onScanned,
  }) async {
    final bytes = await scan(source);
    if (bytes == null) return null;
    onScanned?.call();
    if (!context.mounted) return null;
    final prepared = await showImagePrepareSheet(
      context,
      bytes,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
      theme: theme,
    );
    if (prepared == null) return null;
    return PreparedImage.fromJpeg(prepared);
  }

  /// Capture + manual corner crop only, no prepare sheet.
  ///
  /// Keeps color: Android uses [AndroidScannerMode.base] (no ML Kit enhance /
  /// B&W filter). The vendored scanner also skips the GMS camera UI entirely.
  Future<Uint8List?> scan(PreparedImageSource source) async {
    final paths = await CunningDocumentScanner.getPictures(
      noOfPages: 1,
      scannerSource: source == PreparedImageSource.camera
          ? ScannerSource.camera
          : ScannerSource.gallery,
      androidScannerMode: AndroidScannerMode.base,
      iosScannerOptions: IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.85,
        defaultFilter: IosDocumentFilter.original,
        showFilterBar: false,
      ),
    );
    if (paths == null || paths.isEmpty) return null;
    final bytes = await File(paths.first).readAsBytes();
    await CunningDocumentScanner.cleanCache();
    return bytes;
  }
}
