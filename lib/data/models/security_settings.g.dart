// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SecuritySettingsAdapter extends TypeAdapter<SecuritySettings> {
  @override
  final int typeId = 4;

  @override
  SecuritySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SecuritySettings(
      darkMode: fields[0] as bool,
      languageCode: fields[1] as String,
      autoClearClipboard: fields[2] as bool,
      hideAppPreviews: fields[3] as bool,
      blockScreenshots: fields[4] as bool,
      defaultStegoMode: fields[5] as StegoMode,
      compressionWarningEnabled: fields[6] as bool,
      defaultPasswordLength: fields[7] as int,
      passwordIncludeUppercase: fields[8] as bool,
      passwordIncludeLowercase: fields[9] as bool,
      passwordIncludeNumbers: fields[10] as bool,
      passwordIncludeSymbols: fields[11] as bool,
      passwordExcludeSimilar: fields[12] as bool,
      passwordExcludeAmbiguous: fields[13] as bool,
      deviceBindingId: fields[14] as String?,
      historyExpiryEnabled: fields[17] as bool,
      historyExpiryDays: fields[18] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SecuritySettings obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.darkMode)
      ..writeByte(1)
      ..write(obj.languageCode)
      ..writeByte(2)
      ..write(obj.autoClearClipboard)
      ..writeByte(3)
      ..write(obj.hideAppPreviews)
      ..writeByte(4)
      ..write(obj.blockScreenshots)
      ..writeByte(5)
      ..write(obj.defaultStegoMode)
      ..writeByte(6)
      ..write(obj.compressionWarningEnabled)
      ..writeByte(7)
      ..write(obj.defaultPasswordLength)
      ..writeByte(8)
      ..write(obj.passwordIncludeUppercase)
      ..writeByte(9)
      ..write(obj.passwordIncludeLowercase)
      ..writeByte(10)
      ..write(obj.passwordIncludeNumbers)
      ..writeByte(11)
      ..write(obj.passwordIncludeSymbols)
      ..writeByte(12)
      ..write(obj.passwordExcludeSimilar)
      ..writeByte(13)
      ..write(obj.passwordExcludeAmbiguous)
      ..writeByte(14)
      ..write(obj.deviceBindingId)
      ..writeByte(17)
      ..write(obj.historyExpiryEnabled)
      ..writeByte(18)
      ..write(obj.historyExpiryDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecuritySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
