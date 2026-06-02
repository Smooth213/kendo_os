import 'dart:io';
void main() {
  final files = [
    'lib/infrastructure/persistence/models/match_entity.g.dart', 
    'lib/infrastructure/persistence/models/local_stroke_model.g.dart',
    'lib/infrastructure/persistence/models/match_comment_entity.g.dart',
    'lib/infrastructure/persistence/models/match_command_entity.g.dart',
    'lib/infrastructure/persistence/models/match_projection_entity.g.dart'
  ];
  int counter = 100;
  final regex = RegExp(r'id:\s*(-?\d{10,20})');
  // 修正: 'name:' が前にある場合でも確実に CollectionSchema の ID をキャプチャできるようにする
  final schemaRegex = RegExp(r'(?:CollectionSchema|IndexSchema|Schema)(?:<[^>]+>)?\s*\([\s\S]*?id:\s*(-?\d+)');

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String content = file.readAsStringSync();
    
    final schemaIds = <String>{};
    for (final match in schemaRegex.allMatches(content)) {
      if (match.group(1) != null) {
        schemaIds.add(match.group(1)!);
      }
    }

    content = content.replaceAllMapped(regex, (match) {
      final idValue = match.group(1)!;
      if (schemaIds.contains(idValue)) {
        return match.group(0)!;
      }
      return 'id: ${counter++}';
    });
    file.writeAsStringSync(content);
  }
}
