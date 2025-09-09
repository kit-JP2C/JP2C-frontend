import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static Future<String> saveTempImage(File file) async {
    final dir = await getTemporaryDirectory();
    final target = File(
      "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg",
    );
    await file.copy(target.path);
    return target.path;
  }
}
