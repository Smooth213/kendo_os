/// アプリケーションの動作環境（インフラ・デプロイ環境）のみを定義する責務を持つ。
/// UIの権限やユーザーロールの責務からは完全隔離される。
enum RuntimeMode { beta, release, internal }
