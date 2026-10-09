import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Re-encode pixels on an isolate before publishing. Fresh image allocation
/// intentionally drops EXIF/GPS, camera identifiers, thumbnails and text chunks.
Future<Uint8List> prepareWorkerPhoto(Uint8List bytes) =>
    compute(sanitizeWorkerPhoto, bytes);

Uint8List sanitizeWorkerPhoto(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
    throw const FormatException('Choose a photo smaller than 5 MB.');
  }
  try {
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null ||
        info.width < 1 ||
        info.height < 1 ||
        info.width > 8000 ||
        info.height > 8000 ||
        info.width * info.height > 16000000) {
      throw const FormatException('Choose a photo of up to 16 megapixels.');
    }
    final decoded = decoder!.decodeFrame(0);
    if (decoded == null) {
      throw const FormatException('This photo could not be read.');
    }
    var oriented = img.bakeOrientation(decoded);
    if (oriented.width > 1600 || oriented.height > 1600) {
      oriented = img.copyResize(
        oriented,
        width: oriented.width >= oriented.height ? 1600 : null,
        height: oriented.height > oriented.width ? 1600 : null,
      );
    }
    final clean = img.Image(
      width: oriented.width,
      height: oriented.height,
      numChannels: 3,
    );
    img.fill(clean, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(clean, oriented);
    return img.encodeJpg(clean, quality: 85);
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException(
      'This photo could not be read. Choose a different image.',
    );
  }
}
