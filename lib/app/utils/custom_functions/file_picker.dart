// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:arenabook/app/utils/custom_functions/functions.dart';

import 'logger.dart';

// file picker from local storage
class PickFiles {
  pickfile(files, {String? selectedOption}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: (selectedOption == 'Images/Videos') ? FileType.media : FileType.any,
    );
    return setFileConfigs(result, files);
  }

  // Result means picked Files , files means existing files ---------
  static setFileConfigs(result, files) async {
    // for intent and files handling ----
    var theResult = result is FilePickerResult ? result.files : result;
    if (result != null) {
      if (files != null) {
        for (var i = 0; i < theResult.length; i++) {
          theResult[i] =
              result is FilePickerResult ? await resizeImageFile(theResult[i]) : await resizeImageFile(await createPlatformFileFromPath(theResult[i].path));
          List<String> charactersToReplace = ["&", "\$", "+", ",", ":", ";", "=", "?", "@", "#", " ", "<", ">", "[", "]", "{", "}", "|", "^", "%"];
          String pattern = "[${charactersToReplace.map((char) => RegExp.escape(char)).join()}]";
          RegExp unsafeCharactersPattern = RegExp(pattern);

          var safename = result is FilePickerResult?
              ? theResult[i].name.replaceAll(unsafeCharactersPattern, '_')
              : Functions.extractFileName(theResult[i].path ?? '').replaceAll(unsafeCharactersPattern, '_');

          files.add(<String, dynamic>{
            'name': safename,
            'path': theResult[i].path, //result is FilePickerResult ? result.files[i].path : result[i].path,
          });
        }
      } else {
        files = theResult; //result.files;
      }

      return files;
    }
  }

  // Resizing image -------------------------------------
  static dynamic resizeImageFile(platformFile) async {
    try {
      if (isImageFile(platformFile.path)) {
        // Load the image as bytes from PlatformFile
        final imageBytes =
            // platformFile is PlatformFile ?
            // platformFile.bytes ?? await File(platformFile.path).readAsBytes() :
            await File(platformFile.path!).readAsBytes();
        final codec = await instantiateImageCodec(imageBytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // Define maximum dimensions
        const maxWidth = 1024;
        const maxHeight = 768;
        int width = image.width;
        int height = image.height;

        // Calculate new dimensions while preserving aspect ratio
        if (width > height) {
          if (width > maxWidth) {
            height = (height * maxWidth / width).round();
            width = maxWidth;
          }
        } else {
          if (height > maxHeight) {
            width = (width * maxHeight / height).round();
            height = maxHeight;
          }
        }

        // Resize the image using Canvas
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint();
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          paint,
        );
        final resizedImage = await recorder.endRecording().toImage(width, height);
        final byteData = await resizedImage.toByteData(format: ImageByteFormat.png);
        final resizedBytes = byteData!.buffer.asUint8List();

        // Save resized image to a temporary file
        final tempDir = await getTemporaryDirectory();
        final resizedFile = File('${tempDir.path}/${platformFile.name}');
        await resizedFile.writeAsBytes(resizedBytes);

        // Convert the resized file back to PlatformFile
        final resizedPlatformFile = PlatformFile(
          name: platformFile.name,
          size: resizedBytes.length,
          bytes: resizedBytes,
          path: resizedFile.path,
        );

        return resizedPlatformFile;
      } else {
        return platformFile;
      }
    } catch (e) {
      Logger.logs("Image resize error: $e");
      // return null;
    }
  }

  static Future<PlatformFile?> createPlatformFileFromPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        Logger.logs("File does not exist at the given path.");
        return null;
      }

      // Read file bytes and get file size
      final bytes = await file.readAsBytes();
      final fileSize = await file.length();

      // Create a PlatformFile
      final platformFile = PlatformFile(
        name: file.uri.pathSegments.last,
        path: path,
        bytes: bytes,
        size: fileSize,
      );

      return platformFile;
    } catch (e) {
      Logger.logs("Error creating PlatformFile: $e");
      return null;
    }
  }

  static bool isImageFile(String filePath) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'tiff'];
    final extension = filePath.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  /*
  static setFileConfigsForIntent(result, files) {
    if (result != null) {
      if (files != null) {
        for (var i = 0; i < result.length; i++) {
          List<String> charactersToReplace = ["&", "\$", "+", ",", ":", ";", "=", "?", "@", "#", " ", "<", ">", "[", "]", "{", "}", "|", "^", "%"];
          String pattern = "[${charactersToReplace.map((char) => RegExp.escape(char)).join()}]";
          RegExp unsafeCharactersPattern = RegExp(pattern);

          var safename = Functions.extractFileName(result[i].path ?? '').replaceAll(unsafeCharactersPattern, '_');

          files.add(<String, dynamic>{
            'name': safename,
            'path': result[i].path,
          });
        }
      } else {
        files = result;
      }

      return files;
    }
  }
  */
}
