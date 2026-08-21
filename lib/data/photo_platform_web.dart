import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

Future<String> persistPickedPhoto(XFile file) async {
  final bytes = await file.readAsBytes();
  final mime = file.mimeType ?? 'image/jpeg';
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

Widget buildFilePhoto(
  String path, {
  required BoxFit fit,
  required Alignment alignment,
  required Widget Function(BuildContext, Object, StackTrace?) errorBuilder,
}) {
  return Builder(
    builder: (context) => errorBuilder(context, 'unsupported on web', null),
  );
}
