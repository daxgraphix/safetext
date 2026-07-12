import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ShareIntentService {
  static const _methodChannel = MethodChannel('co.cyberswahili.safetext/share_intent');
  static const _eventChannel = EventChannel('co.cyberswahili.safetext/share_events');
  
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  /// Stream of shared files received while the app is running or just started.
  Stream<List<String>> get shareStream => _eventChannel
      .receiveBroadcastStream()
      .map((dynamic event) => (event as List<dynamic>).cast<String>());

  /// For getting the initial shared files if they were received before the stream was active.
  Future<List<String>?> getInitialSharedFiles() async {
    try {
      final List<dynamic>? paths = await _methodChannel.invokeMethod('getSharedFiles');
      return paths?.cast<String>();
    } on PlatformException catch (e) {
      debugPrint("Failed to get shared files: '${e.message}'.");
      return null;
    }
  }
}
