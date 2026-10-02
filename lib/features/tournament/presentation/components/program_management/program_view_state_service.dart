import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🥋 プログラム閲覧状態（選択中プログラムおよびPDFページ位置）の端末永続化サービス
///
/// メモリ内キャッシュ（即座・同期読み込み）と [SharedPreferences]（ローカルストレージ永続化）の
/// ハイブリッド構成により、Webおよびネイティブアプリ双方で待ち時間ゼロ（0ms）の高速復元を実現します。
class ProgramViewStateService {
  static ProgramViewStateService _instance = ProgramViewStateService._();
  static ProgramViewStateService get instance => _instance;

  @visibleForTesting
  static set instance(ProgramViewStateService mock) => _instance = mock;

  SharedPreferences? _prefs;
  final Map<String, int> _programIndexCache = {};
  final Map<String, int> _pageNumberCache = {};

  ProgramViewStateService._() {
    _initPrefsAsync();
  }

  Future<void> _initPrefsAsync() async {
    if (_prefs != null) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint(
        '[WARN] [ProgramViewStateService] SharedPreferences 初期化スキップ: $e',
      );
    }
  }

  /// テストまたは明示的な [SharedPreferences] 注入初期化
  Future<void> init({SharedPreferences? prefs}) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[WARN] [ProgramViewStateService] init エラー: $e');
    }
  }

  static String _idxKey(String tournamentId) =>
      'kendo_os_prog_last_idx_$tournamentId';
  static String _pageKey(String programKey) =>
      'kendo_os_prog_last_page_$programKey';

  /// 大会ごとに前回選択されていたプログラムのインデックスを取得（同期的・即時返却）
  int getLastProgramIndex(String tournamentId, {int defaultIndex = 0}) {
    if (tournamentId.isEmpty) return defaultIndex;
    if (_programIndexCache.containsKey(tournamentId)) {
      final cached = _programIndexCache[tournamentId]!;
      return cached >= 0 ? cached : defaultIndex;
    }
    try {
      final saved = _prefs?.getInt(_idxKey(tournamentId));
      if (saved != null) {
        final valid = saved >= 0 ? saved : defaultIndex;
        _programIndexCache[tournamentId] = valid;
        return valid;
      }
    } catch (e) {
      debugPrint('[WARN] [ProgramViewStateService] 破損データ検出、デフォルト値へ自己修復: $e');
    }
    return defaultIndex;
  }

  /// 大会ごとに前回選択されていたプログラムのインデックスを保存
  void setLastProgramIndex(String tournamentId, int index) {
    if (tournamentId.isEmpty) return;
    final validIndex = index >= 0 ? index : 0;
    _programIndexCache[tournamentId] = validIndex;
    try {
      _prefs?.setInt(_idxKey(tournamentId), validIndex);
    } catch (e) {
      debugPrint(
        '[WARN] [ProgramViewStateService] setLastProgramIndex 保存エラー: $e',
      );
    }
  }

  /// プログラム（PDF）ごとに前回閲覧していたページ番号（1-indexed）を取得
  int getLastPageNumber(String programKey, {int defaultPage = 1}) {
    if (programKey.isEmpty) return defaultPage;
    if (_pageNumberCache.containsKey(programKey)) {
      final cached = _pageNumberCache[programKey]!;
      return cached >= 1 ? cached : defaultPage;
    }
    try {
      final saved = _prefs?.getInt(_pageKey(programKey));
      if (saved != null) {
        final valid = saved >= 1 ? saved : defaultPage;
        _pageNumberCache[programKey] = valid;
        return valid;
      }
    } catch (e) {
      debugPrint('[WARN] [ProgramViewStateService] 破損ページ番号検出、1ページ目へ自己修復: $e');
    }
    return defaultPage;
  }

  /// プログラム（PDF）ごとに前回閲覧していたページ番号（1-indexed）を保存
  void setLastPageNumber(String programKey, int pageNumber) {
    if (programKey.isEmpty) return;
    final validPage = pageNumber >= 1 ? pageNumber : 1;
    _pageNumberCache[programKey] = validPage;
    try {
      _prefs?.setInt(_pageKey(programKey), validPage);
    } catch (e) {
      debugPrint(
        '[WARN] [ProgramViewStateService] setLastPageNumber 保存エラー: $e',
      );
    }
  }

  /// テスト用状態クリア
  @visibleForTesting
  void resetForTesting() {
    _programIndexCache.clear();
    _pageNumberCache.clear();
    _prefs = null;
  }
}
