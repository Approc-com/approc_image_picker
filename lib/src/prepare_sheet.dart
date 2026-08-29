import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'prepare_jpeg.dart';
import 'prepare_theme.dart';

/// Bottom sheet: rotate, optional resize or compress, then return JPEG bytes.
Future<Uint8List?> showImagePrepareSheet(
  BuildContext context,
  Uint8List bytes, {
  int maxDimension = kDefaultMaxDimension,
  int jpegQuality = kDefaultJpegQuality,
  ImagePrepareTheme theme = const ImagePrepareTheme(),
}) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ImagePrepareSheet(
      bytes: bytes,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
      theme: theme,
    ),
  );
}

/// Prepare-sheet UI. Prefer [showImagePrepareSheet] or [ApprocImagePicker.pick].
class ImagePrepareSheet extends StatefulWidget {
  const ImagePrepareSheet({
    super.key,
    required this.bytes,
    this.maxDimension = kDefaultMaxDimension,
    this.jpegQuality = kDefaultJpegQuality,
    this.theme = const ImagePrepareTheme(),
  });

  final Uint8List bytes;
  final int maxDimension;
  final int jpegQuality;
  final ImagePrepareTheme theme;

  @override
  State<ImagePrepareSheet> createState() => _ImagePrepareSheetState();
}

class _ImagePrepareSheetState extends State<ImagePrepareSheet> {
  late final _maxDim = TextEditingController(text: '${widget.maxDimension}');
  late final _quality = TextEditingController(text: '${widget.jpegQuality}');

  var _turns = 0;
  var _op = ImagePrepareOp.none;
  var _busy = false;
  String? _error;
  late final int _srcW;
  late final int _srcH;

  @override
  void initState() {
    super.initState();
    final decoded = img.decodeImage(widget.bytes);
    final upright = decoded == null ? null : img.bakeOrientation(decoded);
    _srcW = upright?.width ?? 0;
    _srcH = upright?.height ?? 0;
  }

  @override
  void dispose() {
    _maxDim.dispose();
    _quality.dispose();
    super.dispose();
  }

  int get _viewW => _turns.isOdd ? _srcH : _srcW;
  int get _viewH => _turns.isOdd ? _srcW : _srcH;

  void _use() {
    if (_busy) return;
    var maxDimension = widget.maxDimension;
    var quality = widget.jpegQuality;
    if (_op == ImagePrepareOp.resize) {
      maxDimension = int.tryParse(_maxDim.text) ?? 0;
      if (maxDimension < 1) {
        setState(() => _error = widget.theme.labels.errorMaxDimension);
        return;
      }
    } else if (_op == ImagePrepareOp.compress) {
      quality = int.tryParse(_quality.text) ?? 0;
      if (quality < 1 || quality > 100) {
        setState(() => _error = widget.theme.labels.errorQuality);
        return;
      }
    }

    setState(() => _busy = true);
    final out = prepareJpeg(
      widget.bytes,
      quarterTurns: _turns,
      maxDimension: maxDimension,
      quality: quality,
    );
    if (!mounted) return;
    Navigator.of(context).pop(out);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labels = widget.theme.labels;
    final muted = TextStyle(color: colors.onSurface.withValues(alpha: 0.55));
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(labels.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: _turns,
                    child: Image.memory(widget.bytes, height: 160, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_viewW × $_viewH px  ·  ${(widget.bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB',
              textAlign: TextAlign.center,
              style: muted,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: labels.rotateLeft,
                  onPressed: _busy ? null : () => setState(() => _turns = (_turns + 3) % 4),
                  icon: const Icon(Icons.rotate_left),
                ),
                IconButton(
                  tooltip: labels.rotateRight,
                  onPressed: _busy ? null : () => setState(() => _turns = (_turns + 1) % 4),
                  icon: const Icon(Icons.rotate_right),
                ),
              ],
            ),
            SegmentedButton<ImagePrepareOp>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: ImagePrepareOp.resize, label: Text(labels.resize), icon: const Icon(Icons.photo_size_select_large)),
                ButtonSegment(value: ImagePrepareOp.compress, label: Text(labels.compress), icon: const Icon(Icons.compress)),
              ],
              selected: _op == ImagePrepareOp.none ? const {} : {_op},
              onSelectionChanged: (next) {
                if (_busy) return;
                setState(() {
                  _op = next.isEmpty ? ImagePrepareOp.none : next.first;
                  _error = null;
                });
              },
            ),
            if (_op == ImagePrepareOp.resize) ...[
              const SizedBox(height: 12),
              _NumField(controller: _maxDim, label: labels.maxDimension, enabled: !_busy),
              const SizedBox(height: 6),
              Text(labels.maxDimensionHint, style: muted.copyWith(fontSize: 12)),
            ],
            if (_op == ImagePrepareOp.compress) ...[
              const SizedBox(height: 12),
              _NumField(controller: _quality, label: labels.quality, enabled: !_busy),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(error, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: widget.theme.cancelButtonBuilder?.call(
                        context,
                        _busy ? null : () => Navigator.of(context).pop(),
                        _busy,
                      ) ??
                      OutlinedButton(
                        onPressed: _busy ? null : () => Navigator.of(context).pop(),
                        child: Text(labels.cancel),
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: widget.theme.confirmButtonBuilder?.call(
                        context,
                        _busy ? null : _use,
                        _busy,
                      ) ??
                      FilledButton(
                        onPressed: _busy ? null : _use,
                        child: _busy
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                              )
                            : Text(labels.useImage),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.controller, required this.label, required this.enabled});

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: Theme.of(context).inputDecorationTheme.border ?? const OutlineInputBorder(),
      ),
    );
  }
}
