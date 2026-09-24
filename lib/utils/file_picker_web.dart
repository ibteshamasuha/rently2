// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';

Future<List<String>> pickImagesFromDevice() async {
  final completer = Completer<List<String>>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';
  uploadInput.multiple = true;
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completer.complete([]);
      return;
    }

    final List<String> results = [];
    int readCount = 0;

    for (final file in files) {
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((event) {
        if (reader.result != null) {
          results.add(reader.result.toString());
        }
        readCount++;
        if (readCount == files.length) {
          completer.complete(results);
        }
      });
      reader.onError.listen((err) {
        readCount++;
        if (readCount == files.length) {
          completer.complete(results);
        }
      });
    }
  });

  return completer.future;
}
