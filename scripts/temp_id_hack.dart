import 'dart:io';
void main() {
  final files = [
    'lib/infrastructure/persistence/models/match_entity.g.dart', 
    'lib/infrastructure/persistence/models/local_stroke_model.g.dart',
    'lib/infrastructure/persistence/models/match_comment_entity.g.dart',
    'lib/infrastructure/persistence/models/match_command_entity.g.dart'
  ];
  int counter = 100;
  final regex = RegExp(r'id:\s*-?\d{10,20}');
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    content = content.replaceAllMapped(regex, (match) => 'id: ${counter++}');
    file.writeAsStringSync(content);
  }
}
