import 'package:kendo_os/features/match/domain/match_model.dart';

/// 試合編集シート用の文字列抽出・クレンジングヘルパー
class MatchEditDataHelper {
  static String extractTeamName(
    String rawName,
    String fallback,
    bool isDantai,
  ) {
    if (rawName.contains(':')) {
      final teamPart = rawName.split(':').first.trim();
      if (teamPart.isNotEmpty) return teamPart;
    }
    if (rawName.isNotEmpty && !rawName.contains(':') && isDantai) {
      return rawName.trim();
    }
    return fallback;
  }

  static String extractPlayerName(String rawName) {
    if (rawName.contains(':')) {
      return rawName.split(':').last.trim();
    }
    return rawName.trim();
  }

  static String extractHeadingText(MatchModel match) {
    final rawNote = match.note.trim();
    if (rawNote.isEmpty) return '';

    final firstLine = rawNote.split('\n').first.trim();
    final isUuidNote = RegExp(
      r'^[a-f0-9\-]{20,}$',
      caseSensitive: false,
    ).hasMatch(firstLine);

    if (isUuidNote) return '';

    if (!firstLine.contains(' vs ') &&
        (firstLine.contains('試合場') ||
            firstLine.contains('コート') ||
            firstLine.contains('回戦') ||
            firstLine.contains('リーグ') ||
            firstLine.contains('試合目') ||
            firstLine.contains(','))) {
      return firstLine;
    }

    return '';
  }

  static String cleanNoteText(String rawNote) {
    if (rawNote.isEmpty) return '';
    final lines = rawNote.split('\n');
    if (lines.isEmpty) return '';

    final firstLine = lines.first.trim();
    final isHeadingLine =
        !firstLine.contains(' vs ') &&
        (firstLine.contains('試合場') ||
            firstLine.contains('コート') ||
            firstLine.contains('回戦') ||
            firstLine.contains('リーグ') ||
            firstLine.contains('試合目') ||
            firstLine.contains(','));

    final noteLines = (isHeadingLine || firstLine.contains(' vs '))
        ? lines.skip(1).where((line) => line.trim().isNotEmpty).toList()
        : lines.where((line) => line.trim().isNotEmpty).toList();

    return noteLines.join('\n').trim();
  }

  static String getPositionLabel(int index, int total) {
    if (total == 5) {
      const pos = ['先鋒', '次鋒', '中堅', '副将', '大将'];
      if (index < pos.length) return pos[index];
    } else if (total == 3) {
      const pos = ['先鋒', '中堅', '大将'];
      if (index < pos.length) return pos[index];
    }
    return '第${index + 1}試合';
  }
}
