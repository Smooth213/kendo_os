// 重複定義による権限の分散（常にViewerに戻ってしまう不具合）を防ぐため、
// 中央管理の currentUserRoleProvider へ転送します。
export 'current_user_role_provider.dart';