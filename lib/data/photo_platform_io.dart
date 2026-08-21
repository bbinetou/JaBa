import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String> persistPickedPhoto(XFile file) async {
  final bytes = await file.readAsBytes();
  final dir = await getApplicationDocumentsDirectory();
  final photosDir = Directory('${dir.path}/listing_photos');
  if (!await photosDir.exists()) {
    await photosDir.create(recursive: true);
  }
  final saved = File(
      '${photosDir.path}/p${DateTime.now().microsecondsSinceEpoch}${_extensionOf(file.name)}');
  await saved.writeAsBytes(bytes);
  return saved.path;
}

String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot == -1 ? '.jpg' : name.substring(dot);
}

Widget buildFilePhoto(
  String path, {
  required BoxFit fit,
  required Alignment alignment,
  required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
}) {
  return Image.file(
    File(path),
    fit: fit,
    alignment: alignment,
    gaplessPlayback: true,
    errorBuilder: errorBuilder,
  );
}
