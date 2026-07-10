import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:image/image.dart' as img;

import '../exceptions/app_exceptions.dart';

/// Plain LSB (least-significant-bit) text steganography — **no
/// encryption**. This backs the "LSB on Text" module, a simpler sibling to
/// the app's core Ghost/Armor engine (`StegoService`) and to "LSB with
/// DES" (`DesCryptoService` + this class combined).
///
/// Frame layout embedded sequentially across RGB channels of a lossless
/// PNG:
/// ```
/// magic (4 bytes "LSBT") | length (4 bytes, big-endian) | UTF-8 bytes
/// ```
///
/// Because there is no encryption layer, anyone who extracts the payload
/// can read it immediately — this mode only hides that a message exists,
/// it does not protect its contents. The UI makes this distinction clear
/// and defaults to recommending "LSB with DES" or the core SafeText
/// (AES-256-GCM) encoder whenever confidentiality actually matters.
class LsbSteganographyService {
  const LsbSteganographyService();

  static const int _magic = 0x4C534254; // "LSBT"
  static const int _headerBytes = 8; // magic(4) + length(4)

  /// Theoretical maximum message bytes this [imageBytes] carrier can hold.
  Future<int> maxCapacityBytes(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw const InvalidImageException();
    final totalChannels = decoded.width * decoded.height * 3;
    final availableBits = totalChannels - (_headerBytes * 8);
    if (availableBits <= 0) return 0;
    return availableBits ~/ 8;
  }

  Future<Uint8List> embed({required Uint8List imageBytes, required String message}) async {
    return Isolate.run(() {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw const InvalidImageException();

      final messageBytes = Uint8List.fromList(utf8.encode(message));
      final totalChannels = image.width * image.height * 3;
      final neededBits = (_headerBytes + messageBytes.length) * 8;
      if (neededBits > totalChannels) {
        throw const InsufficientCapacityException('Image is too small to hold this message.');
      }

      final header = ByteData(_headerBytes)
        ..setUint32(0, _magic, Endian.big)
        ..setUint32(4, messageBytes.length, Endian.big);

      final frame = Uint8List(_headerBytes + messageBytes.length)
        ..setRange(0, _headerBytes, header.buffer.asUint8List())
        ..setRange(_headerBytes, _headerBytes + messageBytes.length, messageBytes);

      final bits = _bytesToBits(frame);

      for (int i = 0; i < bits.length; i++) {
        final pixelIndex = i ~/ 3;
        final channel = i % 3;
        final x = pixelIndex % image.width;
        final y = pixelIndex ~/ image.width;
        final pixel = image.getPixel(x, y);
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        channels[channel] = (channels[channel] & ~1) | bits[i];
        image.setPixelRgba(x, y, channels[0], channels[1], channels[2], pixel.a.toInt());
      }

      return Uint8List.fromList(img.encodePng(image));
    });
  }

  Future<String> extract(Uint8List imageBytes) async {
    return Isolate.run(() {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw const InvalidImageException();

      final totalChannels = image.width * image.height * 3;
      const headerBitCount = _headerBytes * 8;
      if (headerBitCount > totalChannels) throw const NoPayloadFoundException();

      int readBit(int i) {
        final pixelIndex = i ~/ 3;
        final channel = i % 3;
        final x = pixelIndex % image.width;
        final y = pixelIndex ~/ image.width;
        final pixel = image.getPixel(x, y);
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        return channels[channel] & 1;
      }

      final headerBits = List<int>.generate(headerBitCount, readBit);
      final headerBytes = _bitsToBytes(headerBits);
      final headerData = ByteData.sublistView(headerBytes);

      final magic = headerData.getUint32(0, Endian.big);
      if (magic != _magic) throw const NoPayloadFoundException();

      final length = headerData.getUint32(4, Endian.big);
      final totalBitsNeeded = headerBitCount + length * 8;
      if (length <= 0 || totalBitsNeeded > totalChannels) throw const NoPayloadFoundException();

      final messageBits = List<int>.generate(length * 8, (i) => readBit(headerBitCount + i));
      final messageBytes = _bitsToBytes(messageBits);

      try {
        return utf8.decode(messageBytes);
      } catch (_) {
        throw const NoPayloadFoundException('Payload found but could not be decoded as text.');
      }
    });
  }

  List<int> _bytesToBits(Uint8List bytes) {
    final bits = <int>[];
    for (final byte in bytes) {
      for (int i = 7; i >= 0; i--) {
        bits.add((byte >> i) & 1);
      }
    }
    return bits;
  }

  Uint8List _bitsToBytes(List<int> bits) {
    final byteCount = bits.length ~/ 8;
    final bytes = Uint8List(byteCount);
    for (int i = 0; i < byteCount; i++) {
      int value = 0;
      for (int b = 0; b < 8; b++) {
        value = (value << 1) | bits[i * 8 + b];
      }
      bytes[i] = value;
    }
    return bytes;
  }
}
