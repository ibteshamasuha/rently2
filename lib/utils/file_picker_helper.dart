import 'file_picker_stub.dart'
    if (dart.library.html) 'file_picker_web.dart' as picker;

Future<List<String>> pickImagesFromDevice() => picker.pickImagesFromDevice();
