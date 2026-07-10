import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';
import 'payload_codec.dart';

/// Result of an image capacity / suitability analysis.
class ImageAnalysis {
  final int width;
  final int height;
  final int maxCapacityBytes;
  final int recommendedCapacityBytes;
  final int securityScore;

  const ImageAnalysis({
    required this.width,
    required this.height,
    required this.maxCapacityBytes,
    required this.recommendedCapacityBytes,
    required this.securityScore,
  });

  String get healthLabel {
    if (securityScore >= 85) return 'Excellent';
    if (securityScore >= 65) return 'Good';
    if (securityScore >= 40) return 'Average';
    return 'Poor';
  }

  /// Returns a status color for the UI "Traffic Light" system.
  int get healthColorValue {
    if (securityScore >= 65) return 0xFF4CAF50; // Green
    if (securityScore >= 40) return 0xFFFFC107; // Amber
    return 0xFFF44336; // Red
  }
}

/// Enhanced LSB steganography engine with background processing,
/// metadata scrubbing, and statistical noise injection.
class StegoService {
  const StegoService();

  final PayloadCodec _codec = const PayloadCodec();

  // ---------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------

  /// Analyzes image capacity in a background isolate.
  Future<ImageAnalysis> analyze(Uint8List imageBytes, {required StegoMode mode}) async {
    return Isolate.run(() {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) throw const InvalidImageException();
      return _analyzeImageSync(decoded, mode);
    });
  }

  ImageAnalysis _analyzeImageSync(img.Image image, StegoMode mode) {
    final totalChannels = image.width * image.height * 3;
    final availableForBody = (totalChannels - PayloadCodec.headerLengthBytes * 8);
    if (availableForBody <= 0) {
      throw const InsufficientCapacityException('Image is too small.');
    }

    final redundancy = mode == StegoMode.armor ? 3 : 1;
    final maxBodyBytes = (availableForBody ~/ redundancy) ~/ 8;
    const overheadBytes = 8 + 16 + 12 + 4 + 16 + 4;
    final maxCapacityBytes = max(0, maxBodyBytes - overheadBytes);
    final recommendedCapacityBytes = (maxCapacityBytes * AppConstants.recommendedCapacityRatio).floor();

    final securityScore = _estimateHealthScore(image);

    return ImageAnalysis(
      width: image.width,
      height: image.height,
      maxCapacityBytes: maxCapacityBytes,
      recommendedCapacityBytes: recommendedCapacityBytes,
      securityScore: securityScore,
    );
  }

  int _estimateHealthScore(img.Image image) {
    final samplesX = min(64, image.width);
    final samplesY = min(64, image.height);
    final stepX = max(1, image.width ~/ samplesX);
    final stepY = max(1, image.height ~/ samplesY);

    final List<double> deltas = [];
    for (int y = 0; y < image.height - stepY; y += stepY) {
      for (int x = 0; x < image.width - stepX; x += stepX) {
        final p1 = image.getPixel(x, y);
        final p2 = image.getPixel(x + stepX, y);
        final l1 = 0.299 * p1.r + 0.587 * p1.g + 0.114 * p1.b;
        final l2 = 0.299 * p2.r + 0.587 * p2.g + 0.114 * p2.b;
        deltas.add((l1 - l2).abs());
      }
    }
    if (deltas.isEmpty) return 50;
    final mean = deltas.reduce((a, b) => a + b) / deltas.length;
    return (mean / 40 * 100).clamp(15, 100).round();
  }

  // ---------------------------------------------------------------------
  // Encoding
  // ---------------------------------------------------------------------

  /// Embeds payload in a background isolate with metadata scrubbing and noise injection.
  Future<Uint8List> embed({
    required Uint8List imageBytes,
    required Uint8List bodyBytes,
    required StegoMode mode,
    required int seed,
  }) async {
    return Isolate.run(() {
      final sourceImage = img.decodeImage(imageBytes);
      if (sourceImage == null) throw const InvalidImageException();

      // [IMPROVEMENT 2: Privacy] - Metadata Scrubbing
      // We create a clean pixel buffer and copy pixels over, effectively 
      // stripping any EXIF/GPS/Metadata from the original carrier.
      final image = img.Image(
        width: sourceImage.width,
        height: sourceImage.height,
        numChannels: 3, // Force RGB to avoid alpha-channel leakage
      );
      for (final pixel in sourceImage) {
        image.setPixelRgb(pixel.x, pixel.y, pixel.r, pixel.g, pixel.b);
      }

      final modeCode = mode == StegoMode.armor ? 1 : 0;
      final header = _codec.buildHeader(mode: modeCode, seed: seed, bodyLength: bodyBytes.length);
      final headerBits = _bytesToBits(header);
      final bodyBitsRaw = _bytesToBits(bodyBytes);
      final bodyBits = modeCode == 1 ? _tripleEncode(bodyBitsRaw) : bodyBitsRaw;

      final totalChannels = image.width * image.height * 3;
      if (headerBits.length + bodyBits.length > totalChannels) {
        throw const InsufficientCapacityException();
      }

      final indexer = _channelIndexer(image.width, image.height);

      // Write Header (Sequential)
      for (int i = 0; i < headerBits.length; i++) {
        _writeBit(image, indexer(i), headerBits[i]);
      }

      final remainingStart = headerBits.length;
      final usedPositionsSet = <int>{};

      // Determine Body Positions
      final List<int> bodyPositions;
      if (modeCode == 0) { // Ghost Mode
        bodyPositions = _sampleDistinctIndices(bodyBits.length, seed, remainingStart, totalChannels);
        usedPositionsSet.addAll(bodyPositions);
      } else { // Armor Mode
        bodyPositions = List<int>.generate(bodyBits.length, (i) => remainingStart + i);
        usedPositionsSet.addAll(bodyPositions);
      }

      // Write Body
      for (int i = 0; i < bodyBits.length; i++) {
        _writeBit(image, indexer(bodyPositions[i]), bodyBits[i]);
      }

      // [IMPROVEMENT 3: Security] - Noise Injection (Ghost Mode Only)
      // Randomly flip LSBs of unused channels to mask the statistical 
      // profile of the modified payload regions.
      if (mode == StegoMode.ghost) {
        final rnd = Random(seed + 1);
        final noiseCount = ((totalChannels - remainingStart - bodyBits.length) * 0.05).round();
        for (int i = 0; i < noiseCount; i++) {
          final pos = remainingStart + rnd.nextInt(totalChannels - remainingStart);
          if (!usedPositionsSet.contains(pos)) {
            final loc = indexer(pos);
            final bit = rnd.nextInt(2);
            _writeBit(image, loc, bit);
          }
        }
      }

      return Uint8List.fromList(img.encodePng(image));
    });
  }

  // ---------------------------------------------------------------------
  // Decoding
  // ---------------------------------------------------------------------

  /// Extracts payload in a background isolate.
  Future<SafeTextPayload> extract(Uint8List imageBytes) async {
    return Isolate.run(() {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw const InvalidImageException();

      final totalChannels = image.width * image.height * 3;
      final indexer = _channelIndexer(image.width, image.height);

      const headerBitCount = PayloadCodec.headerLengthBytes * 8;
      if (headerBitCount > totalChannels) throw const NoPayloadFoundException();

      final headerBits = List<int>.generate(headerBitCount, (i) => _readBit(image, indexer(i)));
      final info = _codec.parseHeader(_bitsToBytes(headerBits));

      final rawBitsNeeded = info.mode == 1 ? info.bodyLength * 8 * 3 : info.bodyLength * 8;
      if (rawBitsNeeded <= 0 || (headerBitCount + rawBitsNeeded) > totalChannels) {
        throw const NoPayloadFoundException();
      }

      final positions = info.mode == 0
          ? _sampleDistinctIndices(rawBitsNeeded, info.seed, headerBitCount, totalChannels)
          : List<int>.generate(rawBitsNeeded, (i) => headerBitCount + i);

      final rawBits = List<int>.generate(rawBitsNeeded, (i) => _readBit(image, indexer(positions[i])));
      final bodyBytes = _bitsToBytes(info.mode == 1 ? _tripleDecode(rawBits) : rawBits);

      return _codec.parseBody(bodyBytes, mode: info.mode, seed: info.seed);
    });
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  _PixelLocator _channelIndexer(int width, int height) {
    return (int idx) => _PixelLocation(idx ~/ 3 % width, idx ~/ 3 ~/ width, idx % 3);
  }

  void _writeBit(img.Image image, _PixelLocation loc, int bit) {
    final pixel = image.getPixel(loc.x, loc.y);
    final c = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
    c[loc.channel] = (c[loc.channel] & ~1) | bit;
    image.setPixelRgb(loc.x, loc.y, c[0], c[1], c[2]);
  }

  int _readBit(img.Image image, _PixelLocation loc) {
    final p = image.getPixel(loc.x, loc.y);
    return [p.r, p.g, p.b][loc.channel].toInt() & 1;
  }

  List<int> _bytesToBits(Uint8List bytes) {
    final bits = <int>[];
    for (var b in bytes) {
      for (int i = 7; i >= 0; i--) {
        bits.add((b >> i) & 1);
      }
    }
    return bits;
  }

  Uint8List _bitsToBytes(List<int> bits) {
    final bytes = Uint8List(bits.length ~/ 8);
    for (int i = 0; i < bytes.length; i++) {
      for (int b = 0; b < 8; b++) {
        bytes[i] = (bytes[i] << 1) | bits[i * 8 + b];
      }
    }
    return bytes;
  }

  List<int> _sampleDistinctIndices(int count, int seed, int start, int end) {
    final rangeSize = end - start;
    final result = List<int>.filled(count, 0);
    final rnd = Random(seed);
    for (int i = 0; i < count; i++) {
      final j = rnd.nextInt(rangeSize - i) + i;
      result[i] = (j < count) ? result[i] : start + j;
    }
    return result;
  }

  List<int> _tripleEncode(List<int> bits) => bits.expand((b) => [b, b, b]).toList();

  List<int> _tripleDecode(List<int> bits) {
    final out = <int>[];
    for (int i = 0; i + 2 < bits.length; i += 3) {
      out.add(bits[i] + bits[i + 1] + bits[i + 2] >= 2 ? 1 : 0);
    }
    return out;
  }
}

typedef _PixelLocator = _PixelLocation Function(int idx);
class _PixelLocation {
  final int x, y, channel;
  const _PixelLocation(this.x, this.y, this.channel);
}
