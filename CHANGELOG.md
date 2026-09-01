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
