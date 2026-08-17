import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Обране фото у вигляді байтів.
///
/// `dart:io File` не існує у веб-збірці — саме звідти бралась помилка
/// `Unsupported operation: _Namespace` і при показі фото, і при створенні
/// події. Байти працюють однаково на всіх платформах, тому екрани
/// завантаження більше не залежать від `dart:io`.
class PickedPhoto {
  final Uint8List bytes;
  final String extension;
  final String mimeType;

  const PickedPhoto({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });

  static Future<PickedPhoto> fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();

    final rawExt = file.name.contains('.') ? file.name.split('.').last : '';
    final ext = rawExt.isEmpty ? 'jpg' : rawExt.toLowerCase();

    // Веб не завжди заповнює mimeType, тож виводимо з розширення.
    final mime = file.mimeType ??
        switch (ext) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          'heic' => 'image/heic',
          _ => 'image/jpeg',
        };

    return PickedPhoto(bytes: bytes, extension: ext, mimeType: mime);
  }
}
