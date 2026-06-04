import '../../domain/entities/user_session.dart';

/// VM（テスト環境）など、Web APIが利用できないプラットフォームで
/// 安全にコンパイルを通過させるためのスタブ実装
class SessionStorage {
  static void save(UserSession session) {}

  static UserSession? load() => null;

  static void clear() {}
}
