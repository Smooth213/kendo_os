import 'dart:typed_data';

/// Web環境向け PlatformFile スタブ
class PlatformFile {
  final String path;
  PlatformFile(this.path);

  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<bool> exists() async => false;
}
