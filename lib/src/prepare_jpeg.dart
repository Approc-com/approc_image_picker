import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Default longest-side cap in pixels. Smaller images are not enlarged.
const kDefaultMaxDimension = 3000;

/// Default JPEG quality (1–100).
const kDefaultJpegQuality = 98;

/// Exclusive prepare-sheet mode. Neither selected still uses the defaults.
enum ImagePrepareOp { none, resize, compress }

/// Bakes EXIF into pixels, optionally rotates, caps the longest side, saves JPEG.
///
/// Does not grayscale, crop, stretch, pad, or upscale.
Uint8List prepareJpeg(
  Uint8List bytes, {
  int quarterTurns = 0,
  int maxDimension = kDefaultMaxDimension,
  int quality = kDefaultJpegQuality,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  // Apply EXIF orientation to pixels first. Saving JPEG drops the tag;
  // if pixels stay sideways, OCR sees a rotated document.
  var image = img.bakeOrientation(decoded);

  final turns = quarterTurns % 4;
  if (turns != 0) {
    image = img.copyRotate(image, angle: turns * 90);
  }

  final longest = math.max(image.width, image.height);
  if (maxDimension > 0 && longest > maxDimension) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: maxDimension,
            interpolation: img.Interpolation.linear,
          )
        : img.copyResize(
            image,
            height: maxDimension,
            interpolation: img.Interpolation.linear,
          );
  }

  image.exif = img.ExifData();
  return Uint8List.fromList(
    img.encodeJpg(image, quality: quality.clamp(1, 100)),
  );
}

/// `bytes.toPreparedJpeg()` — same pipeline as [prepareJpeg].
extension PreparedJpegBytes on Uint8List {
  Uint8List toPreparedJpeg({
    int quarterTurns = 0,
    int maxDimension = kDefaultMaxDimension,
    int quality = kDefaultJpegQuality,
  }) =>
      prepareJpeg(
        this,
        quarterTurns: quarterTurns,
        maxDimension: maxDimension,
        quality: quality,
      );
}
