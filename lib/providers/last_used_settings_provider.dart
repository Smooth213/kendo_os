import 'package:flutter_riverpod/flutter_riverpod.dart';

// 前回使用したルール設定を一時的に保持する保管場所
final lastUsedSettingsProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'matchType': '団体戦（5人制）',
    'category': '小学生の部',
    'matchTime': 3.0,
    'isRunningTime': false,
    'hasExtension': false,
    'hasHantei': false,
  };
});