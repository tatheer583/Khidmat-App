import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:khidmat/marketplace/services/worker_photo_service.dart';

void main() {
  test(
    'public photos retain pixels but strip EXIF GPS and camera identifiers',
    () {
      final source = img.Image(width: 8, height: 4, numChannels: 3);
      img.fill(source, color: img.ColorRgb8(40, 120, 180));
      source.exif.gpsIfd[1] = img.IfdValueAscii('N');
      source.exif.imageIfd[0x010f] = img.IfdValueAscii(
        'PRIVATE-CAMERA-IDENTIFIER',
      );
      final original = img.encodeJpg(source);
      expect(img.decodeJpg(original)!.exif.gpsIfd.containsKey(1), isTrue);
      final prepared = sanitizeWorkerPhoto(original);
      final decoded = img.decodeJpg(prepared)!;
      expect(decoded.width, 8);
      expect(decoded.height, 4);
      expect(decoded.exif.gpsIfd.containsKey(1), isFalse);
      expect(decoded.exif.imageIfd.containsKey(0x010f), isFalse);
      expect(
        latin1.decode(prepared),
        isNot(contains('PRIVATE-CAMERA-IDENTIFIER')),
      );
    },
  );
  test(
    'PNG text metadata is removed and photos are resized before publication',
    () {
      final source = img.Image(
        width: 1700,
        height: 2,
        textData: {'Location': 'PRIVATE-HOME-COORDINATES'},
      );
      final prepared = sanitizeWorkerPhoto(img.encodePng(source));
      final decoded = img.decodeJpg(prepared)!;
      expect(decoded.width, 1600);
      expect(
        latin1.decode(prepared),
        isNot(contains('PRIVATE-HOME-COORDINATES')),
      );
    },
  );
  test('invalid or excessive images never reach publication', () {
    expect(
      () => sanitizeWorkerPhoto(Uint8List.fromList([0xff, 0xd8, 0xff])),
      throwsFormatException,
    );
    expect(
      () => sanitizeWorkerPhoto(Uint8List(5 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
    final source = img.Image(width: 8001, height: 1);
    expect(
      () => sanitizeWorkerPhoto(img.encodePng(source)),
      throwsFormatException,
    );
  });
}
