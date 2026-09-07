# 1.2.0

- Camera uses the same manual corner cropper as gallery (no live auto-detect borders)
- Vendors a forked `cunning_document_scanner` under `packages/cunning_document_scanner`
- Keep color on Android camera: skip ML Kit enhance/B&W (`AndroidScannerMode.base` + fallback decode as ARGB_8888)
- Prepare sheet runs JPEG work off the UI thread so Use image can show loading

# 1.1.1

- `ImagePrepareTheme.showResizeAndCompress` — hide resize/compress; JPEG still uses 3000px / quality 98

# 1.1.0

- Prepare sheet follows host `ThemeData`
- Optional `ImagePrepareTheme` for labels and host Cancel / Use image widgets
- Rename `PreparedImagePicker` → `ApprocImagePicker`

# 1.0.0

- Camera or gallery pick with document crop
- Rotate, resize (longest side), and JPEG compress
- EXIF orientation baked into pixels before save
- Result is always `.jpg`
