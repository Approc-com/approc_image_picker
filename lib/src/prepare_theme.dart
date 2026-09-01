import 'package:flutter/material.dart';

/// Host button for Cancel / Use image. [onPressed] is null while busy.
typedef ImagePrepareButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback? onPressed,
  bool busy,
);

/// User-facing copy. Override for localization.
class ImagePrepareLabels {
  const ImagePrepareLabels({
    this.title = 'Prepare image',
    this.cancel = 'Cancel',
    this.useImage = 'Use image',
    this.resize = 'Resize',
    this.compress = 'Compress',
    this.maxDimension = 'Max dimension (px)',
    this.maxDimensionHint = 'Longest side, keeps aspect ratio.',
    this.quality = 'JPEG quality (1–100)',
    this.rotateLeft = 'Rotate left',
    this.rotateRight = 'Rotate right',
    this.matchOrientation = 'Match this orientation',
    this.errorMaxDimension = 'Enter max dimension in px',
    this.errorQuality = 'Quality must be 1–100',
  });

  final String title;
  final String cancel;
  final String useImage;
  final String resize;
  final String compress;
  final String maxDimension;
  final String maxDimensionHint;
  final String quality;
  final String rotateLeft;
  final String rotateRight;
  final String matchOrientation;
  final String errorMaxDimension;
  final String errorQuality;
}

/// Optional host styling. Omit builders to keep Material buttons (they follow [ThemeData]).
class ImagePrepareTheme {
  const ImagePrepareTheme({
    this.labels = const ImagePrepareLabels(),
    this.cancelButtonBuilder,
    this.confirmButtonBuilder,
    this.showResizeAndCompress = true,
    this.orientationGuide,
  });

  final ImagePrepareLabels labels;
  final ImagePrepareButtonBuilder? cancelButtonBuilder;
  final ImagePrepareButtonBuilder? confirmButtonBuilder;

  /// When false, the sheet is rotate + confirm only. JPEG still uses
  /// [kDefaultMaxDimension] / [kDefaultJpegQuality] (or the picker's values).
  final bool showResizeAndCompress;

  /// Optional example image shown above the user preview so they can match orientation.
  final ImageProvider? orientationGuide;
}
