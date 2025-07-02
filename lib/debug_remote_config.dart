import 'package:flutter/foundation.dart';

class RemoteConfigDebugTester {
  static Future<void> testRemoteConfig() async {
    if (kDebugMode) {
      print('Remote config debug test: Not implemented');
    }
  }
}
