import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'prepare_jpeg.dart';

/// Bottom sheet: rotate, optional resize or compress, then return JPEG bytes.
Future<Uint8List?> showImagePrepareSheet(
  BuildContext context,
  Uint8List bytes, {
  int maxDimension = kDefaultMaxDimension,
  int jpegQuality = kDefaultJpegQuality,
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
    ),
  );
}

/// Prepare-sheet UI. Prefer [showImagePrepareSheet] or [PreparedImagePicker.pick].
class ImagePrepareSheet extends StatefulWidget {
  const ImagePrepareSheet({
    super.key,
    required this.bytes,
    this.maxDimension = kDefaultMaxDimension,
    this.jpegQuality = kDefaultJpegQuality,
  });

  final Uint8List bytes;
  final int maxDimension;
  final int jpegQuality;

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
        setState(() => _error = 'Enter max dimension in px');
        return;
      }
    } else if (_op == ImagePrepareOp.compress) {
      quality = int.tryParse(_quality.text) ?? 0;
      if (quality < 1 || quality > 100) {
        setState(() => _error = 'Quality must be 1–100');
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
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Prepare image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Rotate left',
                  onPressed: _busy ? null : () => setState(() => _turns = (_turns + 3) % 4),
                  icon: const Icon(Icons.rotate_left),
                ),
                IconButton(
                  tooltip: 'Rotate right',
                  onPressed: _busy ? null : () => setState(() => _turns = (_turns + 1) % 4),
                  icon: const Icon(Icons.rotate_right),
                ),
              ],
            ),
            SegmentedButton<ImagePrepareOp>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ImagePrepareOp.resize, label: Text('Resize'), icon: Icon(Icons.photo_size_select_large)),
                ButtonSegment(value: ImagePrepareOp.compress, label: Text('Compress'), icon: Icon(Icons.compress)),
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
              _NumField(controller: _maxDim, label: 'Max dimension (px)', enabled: !_busy),
              const SizedBox(height: 6),
              Text(
                'Longest side, keeps aspect ratio.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
              ),
            ],
            if (_op == ImagePrepareOp.compress) ...[
              const SizedBox(height: 12),
              _NumField(controller: _quality, label: 'JPEG quality (1–100)', enabled: !_busy),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _use,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Use image'),
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
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
