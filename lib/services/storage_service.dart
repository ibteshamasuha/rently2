import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadBase64Image(String dataUrl, String path) async {
    // If it's already a URL, just return it
    if (dataUrl.startsWith('http://') || dataUrl.startsWith('https://')) {
      return dataUrl;
    }

    if (!dataUrl.startsWith('data:image')) {
      throw 'Invalid image data format';
    }

    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1) throw 'Invalid data url';

    final base64String = dataUrl.substring(commaIndex + 1);
    final Uint8List bytes = base64Decode(base64String);

    // Get mime type (e.g. data:image/png;base64)
    final mimeType = dataUrl.substring(dataUrl.indexOf(':') + 1, dataUrl.indexOf(';'));

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: mimeType);

    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }
}
