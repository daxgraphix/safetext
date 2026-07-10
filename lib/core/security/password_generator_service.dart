import 'dart:math';

import '../exceptions/app_exceptions.dart';

/// Character set options for [PasswordGeneratorService.generate].
class PasswordOptions {
  final int length;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeNumbers;
  final bool includeSymbols;
  final bool excludeSimilar; // l, 1, I, O, 0, etc.
  final bool excludeAmbiguous; // { } [ ] ( ) / \ ' " ` ~ , ; : . < >

  const PasswordOptions({
    this.length = 16,
    this.includeUppercase = true,
    this.includeLowercase = true,
    this.includeNumbers = true,
    this.includeSymbols = true,
    this.excludeSimilar = false,
    this.excludeAmbiguous = false,
  });

  bool get hasAnyCharacterClass => includeUppercase || includeLowercase || includeNumbers || includeSymbols;
}

/// Generates cryptographically-random passwords entirely offline using
/// `dart:math`'s `Random.secure()` (CSPRNG) — never a network call, never a
/// predictable seed.
class PasswordGeneratorService {
  const PasswordGeneratorService();

  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?/~`';

  static const String _similarChars = 'il1LoO0';
  static const String _ambiguousChars = '{}[]()/\\\'"`~,;:.<>';

  String generate(PasswordOptions options) {
    if (!options.hasAnyCharacterClass) {
      throw const WeakPassphraseException('Select at least one character type.');
    }
    if (options.length < 4) {
      throw const WeakPassphraseException('Password length must be at least 4.');
    }

    final pools = <String>[];
    if (options.includeUppercase) pools.add(_filter(_uppercase, options));
    if (options.includeLowercase) pools.add(_filter(_lowercase, options));
    if (options.includeNumbers) pools.add(_filter(_numbers, options));
    if (options.includeSymbols) pools.add(_filter(_symbols, options));
    pools.removeWhere((p) => p.isEmpty);

    if (pools.isEmpty) {
      throw const WeakPassphraseException('No characters available with the current filters.');
    }

    final random = Random.secure();
    final fullPool = pools.join();

    // Guarantee at least one character from every selected pool so e.g.
    // "include symbols" can't silently be satisfied 0% of the time by pure
    // chance on short passwords.
    final chars = <String>[
      for (final pool in pools) pool[random.nextInt(pool.length)],
    ];
    while (chars.length < options.length) {
      chars.add(fullPool[random.nextInt(fullPool.length)]);
    }
    chars.shuffle(random);

    return chars.take(options.length).join();
  }

  String _filter(String pool, PasswordOptions options) {
    var result = pool;
    if (options.excludeSimilar) {
      result = result.split('').where((c) => !_similarChars.contains(c)).join();
    }
    if (options.excludeAmbiguous) {
      result = result.split('').where((c) => !_ambiguousChars.contains(c)).join();
    }
    return result;
  }
}
