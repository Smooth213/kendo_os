import 'package:flutter/material.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

/// スコアテーブルカードの試合アイテムモデル
class ScoreTableMatchItem {
  final String id;
  final String matchType;
  final String redName;
  final String whiteName;
  final int redScore;
  final int whiteScore;
  final bool isFinished;
  final bool isSummary;
  final bool isEncho;
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final VoidCallback? onTap;

  const ScoreTableMatchItem({
    required this.id,
    required this.matchType,
    required this.redName,
    required this.whiteName,
    required this.redScore,
    required this.whiteScore,
    required this.isFinished,
    this.isSummary = false,
    this.isEncho = false,
    required this.redPoints,
    required this.whitePoints,
    this.onTap,
  });
}

/// スコアテーブルカードのグループ（対戦枠）情報モデル
class ScoreTableGroupInfo {
  final String groupName;
  final String headerTitle;
  final String scenePrefix;
  final String sideLabelRed;
  final String sideLabelWhite;
  final bool isSummary;
  final String teamWinner;
  final int redWins;
  final int whiteWins;
  final int redTotalPoints;
  final int whiteTotalPoints;
  final bool allFinished;

  const ScoreTableGroupInfo({
    required this.groupName,
    required this.headerTitle,
    this.scenePrefix = '',
    required this.sideLabelRed,
    required this.sideLabelWhite,
    required this.isSummary,
    required this.teamWinner,
    required this.redWins,
    required this.whiteWins,
    required this.redTotalPoints,
    required this.whiteTotalPoints,
    required this.allFinished,
  });
}
