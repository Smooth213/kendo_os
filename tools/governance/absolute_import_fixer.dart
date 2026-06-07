// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found.');
    return;
  }

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  int modifiedFilesCount = 0;

  final regex = RegExp('(import|export)\\s+([\'"])([^\'"]+)\\2');

  for (final file in files) {
    final content = file.readAsStringSync();
    bool isModified = false;

    final relativeToLib = p.relative(file.path, from: 'lib');
    final currentDirRelative = p.dirname(relativeToLib);

    final newContent = content.replaceAllMapped(regex, (match) {
      final keyword = match.group(1)!;
      final quote = match.group(2)!;
      final importPath = match.group(3)!;

      if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
        return match.group(0)!;
      }

      final resolvedPath = p.normalize(p.join(currentDirRelative, importPath));
      final normalizedPath = resolvedPath.replaceAll(r'\', '/');

      final newImport = 'package:kendo_os/$normalizedPath';
      isModified = true;
      return "$keyword $quote$newImport$quote";
    });

    if (isModified && content != newContent) {
      file.writeAsStringSync(newContent);
      modifiedFilesCount++;
      print('Modified: ${file.path}');
    }
  }

  print('Done. Modified $modifiedFilesCount files.');
}
