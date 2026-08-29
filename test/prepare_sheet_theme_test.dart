import 'dart:typed_data';

import 'package:approc_image_picker/approc_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _jpeg() {
  final src = img.Image(width: 80, height: 40);
  img.fill(src, color: img.ColorRgb8(20, 80, 160));
  return Uint8List.fromList(img.encodeJpg(src, quality: 95));
}

Widget _app(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('default sheet follows host ThemeData and Material buttons', (tester) async {
    const titleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w800);
    await tester.pumpWidget(
      _app(
        ImagePrepareSheet(bytes: _jpeg()),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          textTheme: const TextTheme(titleLarge: titleStyle),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Prepare image'));
    expect(title.style?.fontSize, 22);
    expect(find.widgetWithText(FilledButton, 'Use image'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('custom labels replace default copy', (tester) async {
    await tester.pumpWidget(
      _app(
        ImagePrepareSheet(
          bytes: _jpeg(),
          theme: const ImagePrepareTheme(
            labels: ImagePrepareLabels(
              title: 'تجهيز الصورة',
              cancel: 'إلغاء',
              useImage: 'استخدم',
            ),
          ),
        ),
      ),
    );

    expect(find.text('تجهيز الصورة'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
    expect(find.text('استخدم'), findsOneWidget);
    expect(find.text('Prepare image'), findsNothing);
  });

  testWidgets('host button builders replace Material buttons', (tester) async {
    await tester.pumpWidget(
      _app(
        ImagePrepareSheet(
          bytes: _jpeg(),
          theme: ImagePrepareTheme(
            cancelButtonBuilder: (context, onPressed, busy) => TextButton(
              onPressed: onPressed,
              child: const Text('HOST_CANCEL'),
            ),
            confirmButtonBuilder: (context, onPressed, busy) => TextButton(
              onPressed: onPressed,
              child: const Text('HOST_CONFIRM'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('HOST_CANCEL'), findsOneWidget);
    expect(find.text('HOST_CONFIRM'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
