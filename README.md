# approc_image_picker

Pick a photo (camera or gallery), crop the document, then rotate / resize / compress. Output is always **JPEG** (`.jpg`).

Defaults:

- Longest side **3000px** (never upscales, keeps aspect ratio)
- JPEG quality **98**
- EXIF orientation is applied to **pixels** before save (OCR-safe)

## Install

```yaml
dependencies:
  approc_image_picker: ^1.0.0
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

final result = await const PreparedImagePicker().pick(
  context,
  source: PreparedImageSource.camera, // or .gallery
);
if (result == null) return; // cancelled

upload(result.bytes);          // JPEG
print(result.extension);       // jpg
print('${result.width}×${result.height}');
```

Already have bytes:

```dart
final jpeg = bytes.toPreparedJpeg(); // or prepareJpeg(bytes)
```

Show only the prepare sheet:

```dart
final jpeg = await showImagePrepareSheet(context, bytes);
```

## Publish

```bash
cd packages/approc_image_picker
dart pub publish --dry-run
dart pub publish
```
