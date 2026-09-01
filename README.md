# approc_image_picker

Pick a photo (camera or gallery), crop the document, then rotate / resize / compress. Output is always **JPEG** (`.jpg`).

Defaults:

- Longest side **3000px** (never upscales, keeps aspect ratio)
- JPEG quality **98**
- EXIF orientation is applied to **pixels** before save (OCR-safe)

The prepare sheet follows the host `ThemeData`. Pass `ImagePrepareTheme` to localize copy, use the app’s own buttons, or hide resize/compress (`showResizeAndCompress: false`). JPEG still uses 3000px / quality 98.

## Install

```yaml
dependencies:
  approc_image_picker: ^1.1.0
```

Until it is on pub.dev, use a path or git dependency:

```yaml
dependencies:
  approc_image_picker:
    path: packages/approc_image_picker
```

Host app still needs camera permission (`cunning_document_scanner`):

- Android `minSdk` ≥ 24 and `CAMERA` in the manifest
- iOS deployment target ≥ 13 and `NSCameraUsageDescription` in `Info.plist`

## Usage

```dart
import 'package:approc_image_picker/approc_image_picker.dart';

final result = await const ApprocImagePicker().pick(
  context,
  source: PreparedImageSource.camera, // or .gallery
);
if (result == null) return; // cancelled

upload(result.bytes);          // JPEG
print(result.extension);       // jpg
print('${result.width}×${result.height}');
print(result.fileName);        // image.jpg
print(result.sizeInBytes);
```

Hide a loading overlay after crop, before the prepare sheet:

```dart
final result = await const ApprocImagePicker().pick(
  context,
  source: PreparedImageSource.gallery,
  onScanned: hideLoading,
);
```

Scan / crop only (no prepare sheet):

```dart
final bytes = await const ApprocImagePicker().scan(PreparedImageSource.camera);
```

Already have bytes — JPEG pipeline only:

```dart
final jpeg = bytes.toPreparedJpeg(); // or prepareJpeg(bytes)
```

Show only the prepare sheet:

```dart
final jpeg = await showImagePrepareSheet(context, bytes);
```

## Match the host app UI

With no extra setup, Material buttons, colors, and type come from `Theme.of(context)`.

To localize strings and/or swap in app widgets (e.g. `CtaAppButton` in Egypt Consulate):

```dart
final picker = ApprocImagePicker(
  maxDimension: 3000,
  jpegQuality: 98,
  theme: ImagePrepareTheme(
    labels: ImagePrepareLabels(
      title: 'prepare_image'.tr(),
      cancel: 'cancel'.tr(),
      useImage: 'use_image'.tr(),
      resize: 'resize'.tr(),
      compress: 'compress'.tr(),
      maxDimension: 'max_dimension_px'.tr(),
      maxDimensionHint: 'max_dimension_hint'.tr(),
      quality: 'jpeg_quality'.tr(),
      rotateLeft: 'rotate_left'.tr(),
      rotateRight: 'rotate_right'.tr(),
      errorMaxDimension: 'error_max_dimension'.tr(),
      errorQuality: 'error_quality'.tr(),
    ),
    cancelButtonBuilder: (context, onPressed, busy) => CtaAppButton(
      label: 'cancel'.tr(),
      isLoading: busy,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      fullWidth: true,
    ),
    confirmButtonBuilder: (context, onPressed, busy) => CtaAppButton(
      label: 'use_image'.tr(),
      isLoading: busy,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      fullWidth: true,
    ),
  ),
);

final result = await picker.pick(
  context,
  source: PreparedImageSource.camera,
);
```

Omit a builder to keep that Material button; it still uses the app theme.

Same theme works on the sheet alone:

```dart
final jpeg = await showImagePrepareSheet(
  context,
  bytes,
  theme: picker.theme,
);
```

`ImagePrepareButtonBuilder` is `(BuildContext context, VoidCallback? onPressed, bool busy)`. `onPressed` is `null` while the sheet is busy.

## Publish

```bash
cd packages/approc_image_picker
dart pub publish --dry-run
dart pub publish
```
