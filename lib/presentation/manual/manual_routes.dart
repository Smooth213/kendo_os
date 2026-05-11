/// Phase 3-1: Manual IDとファイルパスを紐付けるルーティング定義
enum ManualRoute {
  viewerHome('viewer_home', 'docs/manuals/viewer/index.md'),
  viewerMatch('viewer_match', 'docs/manuals/viewer/viewer_match.md'),
  operateHome('operate_home', 'docs/manuals/operator/index.md'),
  operateMatch('operate_match', 'docs/manuals/operator/match.md'),
  operateCreate('operate_create', 'docs/manuals/operator/create_tournament.md'),
  operateRecord('operate_record', 'docs/manuals/operator/official_record.md'),
  operateAudit('operate_audit', 'docs/manuals/operator/audit_log.md'),
  operateRecovery('operate_recovery', 'docs/manuals/recovery/failure_catalog.md');

  final String id;
  final String path;
  const ManualRoute(this.id, this.path);

  /// IDからRouteを特定する
  static ManualRoute? fromId(String id) {
    for (var route in ManualRoute.values) {
      if (route.id == id) return route;
    }
    return null;
  }
}