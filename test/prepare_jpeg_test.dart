import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:approc_image_picker/approc_image_picker.dart';

Uint8List _jpeg(int w, int h) {
  final src = img.Image(width: w, height: h);
  img.fill(src, color: img.ColorRgb8(20, 80, 160));
  return Uint8List.fromList(img.encodeJpg(src, quality: 95));
}

img.Image _decode(Uint8List bytes) {
  final out = img.decodeImage(bytes);
  expect(out, isNotNull);
  return out!;
}

bool _isJpeg(Uint8List bytes) => bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

void main() {
  test('resize caps longest side and keeps aspect ratio as jpeg', () {
    final out = prepareJpeg(_jpeg(4000, 2000), maxDimension: 3000);

    expect(_isJpeg(out), isTrue);
    final decoded = _decode(out);
    expect(decoded.width, 3000);
    expect(decoded.height, 1500);
  });

  test('resize does not upscale a smaller image', () {
    final out = prepareJpeg(_jpeg(800, 400), maxDimension: 3000);
    final decoded = _decode(out);
    expect(decoded.width, 800);
    expect(decoded.height, 400);
  });

  test('default pipeline caps longest side at 3000', () {
    final out = prepareJpeg(_jpeg(4000, 1000));
    expect(_isJpeg(out), isTrue);
    final decoded = _decode(out);
    expect(decoded.width, 3000);
    expect(decoded.height, 750);
  });

  test('compress keeps size and writes jpeg', () {
    final src = _jpeg(120, 80);
    final out = prepareJpeg(src, quality: 40);
    expect(_isJpeg(out), isTrue);
    final decoded = _decode(out);
    expect(decoded.width, 120);
    expect(decoded.height, 80);
  });

  test('rotate 90 swaps width and height as jpeg', () {
    final out = prepareJpeg(_jpeg(80, 40), quarterTurns: 1);
    expect(_isJpeg(out), isTrue);
    final decoded = _decode(out);
    expect(decoded.width, 40);
    expect(decoded.height, 80);
  });

  test('bakes EXIF orientation into pixels and strips the tag', () {
    final src = img.Image(width: 80, height: 40);
    img.fill(src, color: img.ColorRgb8(20, 80, 160));
    src.exif.imageIfd.orientation = 6;
    final bytes = Uint8List.fromList(img.encodeJpg(src, quality: 98));

    final out = prepareJpeg(bytes);
    expect(_isJpeg(out), isTrue);
    final decoded = _decode(out);
    expect(decoded.exif.imageIfd.hasOrientation, isFalse);
    expect(decoded.width, 40);
    expect(decoded.height, 80);
  });

  test('keeps colour and does not convert to grayscale', () {
    final decoded = _decode(prepareJpeg(_jpeg(120, 80)));
    expect(decoded.numChannels, greaterThanOrEqualTo(3));
    final p = decoded.getPixel(10, 10);
    expect(p.r == p.g && p.g == p.b, isFalse);
  });

  test('extension method matches prepareJpeg', () {
    final src = _jpeg(400, 200);
    expect(src.toPreparedJpeg(), prepareJpeg(src));
  });

  test('PreparedImage.fromJpeg uses jpg extension', () {
    final image = PreparedImage.fromJpeg(prepareJpeg(_jpeg(80, 40)));
    expect(image.extension, 'jpg');
    expect(image.fileName, 'image.jpg');
    expect(image.width, 80);
    expect(image.height, 40);
  });
}
